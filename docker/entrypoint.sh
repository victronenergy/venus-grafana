#!/bin/bash

export G_DIR=/var/lib/grafana

export GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
export GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH="/etc/grafana/provisioning/dashboards/welcome.json"

exec /run.sh
