#!/bin/bash

export G_DIR=/var/lib/grafana

export GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
export GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH="/etc/grafana/provisioning/dashboards/welcome.json"

if [ -n "$VIL_PUBLIC_URL" ]; then
  cp $GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH /tmp/welcome.json.tmpl
  awk '{gsub("__VIL_PUBLIC_URL__", ENVIRON["VIL_PUBLIC_URL"]); print}' < /tmp/welcome.json.tmpl > $GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH
  rm /tmp/welcome.json.tmpl
fi

# Register local Git Sync repositories (if any) and set the home dashboard
# (if requested) once Grafana is up; both run in the background so Grafana
# remains PID 1 via exec below and its startup is never delayed.
/gitsync-bootstrap.sh &
/home-dashboard-bootstrap.sh &

exec /run.sh
