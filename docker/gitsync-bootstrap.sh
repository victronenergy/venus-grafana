#!/bin/bash
#
# Registers a Grafana Git Sync `Repository` resource for a GitHub repository
# described by VIL_GITSYNC_* environment variables, via the Grafana
# provisioning API, once Grafana is up. Started in the background by
# /entrypoint.sh. Does nothing when VIL_GITSYNC_GITHUB_URL is not set.
#
# Environment:
#   VIL_GITSYNC_GITHUB_URL          GitHub repository URL (enables the feature)
#   VIL_GITSYNC_GITHUB_TOKEN        GitHub Personal Access Token
#   VIL_GITSYNC_GITHUB_TOKEN__FILE  Read the token from this file instead
#   VIL_GITSYNC_GITHUB_BRANCH       Branch to sync (default: main)
#   VIL_GITSYNC_GITHUB_PATH         Sub-path holding dashboards (default: repo root)
#   VIL_GITSYNC_NAME                Resource name (default: github-dashboards, "github" is reserved)
#   VIL_GITSYNC_TITLE               Display and folder name (default: GitHub)
#   VIL_GITSYNC_TARGET              folder | folderless (default: folder)
#   VIL_GITSYNC_INTERVAL_SECONDS    Poll interval (default: 60)
#   VIL_GITSYNC_WORKFLOWS           Comma separated: write,branch (default), empty = pull-only
#
# Idempotent: creates the repository, or updates it when it already exists so
# that changed variables take effect on restart. Failures are only logged;
# Grafana keeps running regardless. The token is never printed.

LOG="[gitsync-bootstrap]"

[ -z "$VIL_GITSYNC_GITHUB_URL" ] && exit 0

if [ -n "$VIL_GITSYNC_GITHUB_TOKEN__FILE" ]; then
  if [ -n "$VIL_GITSYNC_GITHUB_TOKEN" ]; then
    echo "$LOG ERROR: both VIL_GITSYNC_GITHUB_TOKEN and VIL_GITSYNC_GITHUB_TOKEN__FILE are set (but are exclusive)"
    exit 0
  fi
  VIL_GITSYNC_GITHUB_TOKEN="$(< "$VIL_GITSYNC_GITHUB_TOKEN__FILE")"
fi

if [ -z "$VIL_GITSYNC_GITHUB_TOKEN" ]; then
  echo "$LOG ERROR: VIL_GITSYNC_GITHUB_URL is set but VIL_GITSYNC_GITHUB_TOKEN is empty, skipping Git Sync setup"
  exit 0
fi

NAME="${VIL_GITSYNC_NAME:-github-dashboards}"
TITLE="${VIL_GITSYNC_TITLE:-GitHub}"
BRANCH="${VIL_GITSYNC_GITHUB_BRANCH:-main}"
GH_PATH="${VIL_GITSYNC_GITHUB_PATH:-}"
TARGET="${VIL_GITSYNC_TARGET:-folder}"
INTERVAL="${VIL_GITSYNC_INTERVAL_SECONDS:-60}"
WORKFLOWS="${VIL_GITSYNC_WORKFLOWS-write,branch}"

BASE_URL="${GRAFANA_BOOTSTRAP_URL:-${GITSYNC_BOOTSTRAP_URL:-http://localhost:${GF_SERVER_HTTP_PORT:-3000}}}"
API="$BASE_URL/apis/provisioning.grafana.app/v0alpha1/namespaces/default/repositories"
AUTH="${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-admin}"

# Minimal JSON string escaping (backslash and double quote).
json_str() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

# "write,branch" -> ["write","branch"]; "" -> []
workflows_json() {
  local out="" item
  IFS=',' read -ra items <<< "$1"
  for item in "${items[@]}"; do
    item="${item// /}"
    [ -z "$item" ] && continue
    out="${out:+$out,}$(json_str "$item")"
  done
  printf '[%s]' "$out"
}

BODY=$(cat <<EOF
{
  "apiVersion": "provisioning.grafana.app/v0alpha1",
  "kind": "Repository",
  "metadata": { "name": $(json_str "$NAME"), "namespace": "default" },
  "spec": {
    "title": $(json_str "$TITLE"),
    "type": "github",
    "github": {
      "url": $(json_str "$VIL_GITSYNC_GITHUB_URL"),
      "branch": $(json_str "$BRANCH"),
      "path": $(json_str "$GH_PATH")
    },
    "sync": { "enabled": true, "target": $(json_str "$TARGET"), "intervalSeconds": ${INTERVAL} },
    "workflows": $(workflows_json "$WORKFLOWS"),
    "webhook": { "disabled": true }
  },
  "secure": { "token": { "create": $(json_str "$VIL_GITSYNC_GITHUB_TOKEN") } }
}
EOF
)

echo "$LOG configuring Git Sync repository '$NAME' for $VIL_GITSYNC_GITHUB_URL ($BRANCH), waiting for Grafana at $BASE_URL"
for _ in $(seq 1 60); do
  curl -sf -o /dev/null "$BASE_URL/api/health" && break
  sleep 2
done
if ! curl -sf -o /dev/null "$BASE_URL/api/health"; then
  echo "$LOG Grafana not healthy after 120s, giving up"
  exit 0
fi

RESP=$(mktemp /tmp/gitsync-resp.XXXXXX)
trap 'rm -f "$RESP"' EXIT

request() {
  # $1 = HTTP method, $2 = URL; body is sent from stdin
  curl -s -o "$RESP" -w '%{http_code}' -u "$AUTH" \
       -H "Content-Type: application/json" -X "$1" --data-binary @- "$2"
}

for attempt in 1 2 3 4 5; do
  code=$(printf '%s' "$BODY" | request POST "$API")
  if [ "$code" = "409" ]; then
    code=$(printf '%s' "$BODY" | request PUT "$API/$NAME")
    action="updated"
  else
    action="created"
  fi
  case "$code" in
    200|201)
      echo "$LOG $action Git Sync repository '$NAME'"
      break ;;
    503|000)
      echo "$LOG API not ready (HTTP $code), retry $attempt/5"
      sleep 3 ;;
    *)
      echo "$LOG failed to configure Git Sync repository '$NAME': HTTP $code: $(tr -d '\n' < "$RESP" | tr -s ' ' | head -c 400)"
      break ;;
  esac
done
