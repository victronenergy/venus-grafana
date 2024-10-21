#!/bin/sh

export G_DIR=/var/lib/grafana

export GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
export GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH="/etc/grafana/provisioning/dashboards/welcome.json"

if [ -n "$VIL_ADMIN_ADDRESS" ]; then
  export WELCOME_TEXT="\n\nGo to venus-influx-loader [admin interface]($VIL_ADMIN_ADDRESS)"
fi

cp $GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH /tmp/welcome.json.tmpl
awk '{gsub("__WELCOME_TEXT__", ENVIRON["WELCOME_TEXT"]); print}' < /tmp/welcome.json.tmpl > $GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH
rm /tmp/welcome.json.tmpl

exec /run.sh
