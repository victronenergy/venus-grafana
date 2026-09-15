#!/bin/bash
#
# Sets the Grafana organization default home dashboard, via the Grafana
# preferences API, once Grafana is up and the dashboard exists. Started in the
# background by /entrypoint.sh. Does nothing when neither variable is set.
#
# Environment:
#   VIL_HOME_DASHBOARD_TITLE  Exact title of the dashboard to show on the home
#                             page, e.g. "Diagnostics". Must match exactly one
#                             dashboard (case sensitive).
#   VIL_HOME_DASHBOARD_UID    Alternatively the dashboard UID, when the title
#                             is ambiguous or you prefer the stable identifier.
#
# Both work for dashboards provisioned from files as well as dashboards synced
# from GitHub (Git Sync). Waits up to 10 minutes for the dashboard to appear,
# so that dashboards which are still being pulled by Git Sync can be selected.
# Failures are only logged; Grafana keeps running regardless.

LOG="[home-dashboard]"

TITLE="$VIL_HOME_DASHBOARD_TITLE"
UID_="$VIL_HOME_DASHBOARD_UID"

[ -z "$TITLE" ] && [ -z "$UID_" ] && exit 0

if [ -n "$TITLE" ] && [ -n "$UID_" ]; then
  echo "$LOG ERROR: both VIL_HOME_DASHBOARD_TITLE and VIL_HOME_DASHBOARD_UID are set (but are exclusive), home dashboard not changed"
  exit 0
fi

BASE_URL="${GRAFANA_BOOTSTRAP_URL:-${GITSYNC_BOOTSTRAP_URL:-http://localhost:${GF_SERVER_HTTP_PORT:-3000}}}"
AUTH="${GF_SECURITY_ADMIN_USER:-admin}:${GF_SECURITY_ADMIN_PASSWORD:-admin}"

# Minimal JSON string escaping (backslash and double quote).
json_str() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

if [ -n "$TITLE" ]; then
  WANT="dashboard titled '$TITLE'"
else
  WANT="dashboard with UID '$UID_'"
fi

echo "$LOG configuring home dashboard: $WANT, waiting for Grafana at $BASE_URL"
for _ in $(seq 1 60); do
  curl -sf -o /dev/null "$BASE_URL/api/health" && break
  sleep 2
done
if ! curl -sf -o /dev/null "$BASE_URL/api/health"; then
  echo "$LOG Grafana not healthy after 120s, giving up"
  exit 0
fi

RESP=$(mktemp /tmp/home-dashboard-resp.XXXXXX)
trap 'rm -f "$RESP"' EXIT

# Searches dashboards by title. Sets `code` to the HTTP status and, on 200,
# `matches` to the search results whose title matches exactly, one JSON object
# per line (empty when there is none). Returns non-zero when the search failed.
search_by_title() {
  code=$(curl -s -o "$RESP" -w '%{http_code}' -u "$AUTH" -G \
         --data-urlencode "query=$TITLE" --data-urlencode "type=dash-db" --data-urlencode "limit=5000" \
         "$BASE_URL/api/search")
  [ "$code" = "200" ] || return 1
  matches=$(sed -E 's/\},\{/}\n{/g' < "$RESP" | grep -F -- "\"title\":$(json_str "$TITLE"),")
  return 0
}

# Resolve UID_, waiting for the dashboard to exist (Git Sync may still be pulling it).
found=""
for attempt in $(seq 1 120); do
  if [ -n "$TITLE" ]; then
    if search_by_title; then
      n=$(printf '%s' "$matches" | grep -c .)
      if [ "$n" -eq 1 ]; then
        UID_=$(printf '%s' "$matches" | sed -E 's/.*"uid":"([^"]*)".*/\1/')
        found=1
        break
      elif [ "$n" -gt 1 ]; then
        echo "$LOG ERROR: $n dashboards are titled '$TITLE', set VIL_HOME_DASHBOARD_UID instead to one of:"
        printf '%s\n' "$matches" | sed -E 's/.*"uid":"([^"]*)".*"url":"([^"]*)".*/  \1  (\2)/'
        echo "$LOG home dashboard not changed"
        exit 0
      fi
    fi
  else
    code=$(curl -s -o /dev/null -w '%{http_code}' -u "$AUTH" "$BASE_URL/api/dashboards/uid/$UID_")
    [ "$code" = "200" ] && found=1 && break
  fi
  case "$code" in
    401|403)
      echo "$LOG cannot query dashboards: HTTP $code, check GF_SECURITY_ADMIN_USER / GF_SECURITY_ADMIN_PASSWORD"
      exit 0 ;;
  esac
  if [ $((attempt % 12)) -eq 0 ]; then
    echo "$LOG $WANT not found yet, still waiting ($((attempt * 5))s)"
  fi
  sleep 5
done
if [ -z "$found" ]; then
  echo "$LOG $WANT not found after 600s, home dashboard not changed"
  exit 0
fi

BODY="{ \"homeDashboardUID\": $(json_str "$UID_") }"

for attempt in 1 2 3 4 5; do
  code=$(printf '%s' "$BODY" | curl -s -o "$RESP" -w '%{http_code}' -u "$AUTH" \
         -H "Content-Type: application/json" -X PATCH --data-binary @- "$BASE_URL/api/org/preferences")
  case "$code" in
    200)
      echo "$LOG set home dashboard to $WANT (uid '$UID_')"
      break ;;
    503|000)
      echo "$LOG API not ready (HTTP $code), retry $attempt/5"
      sleep 3 ;;
    *)
      echo "$LOG failed to set home dashboard: HTTP $code: $(tr -d '\n' < "$RESP" | tr -s ' ' | head -c 400)"
      break ;;
  esac
done
