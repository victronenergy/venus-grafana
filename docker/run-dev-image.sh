#!/bin/bash

VER=develop

OWNER=${OWNER:="victronenergy"}
TARGET=venus-grafana

TAG="$OWNER/$TARGET:${VER}"

NETWORK="vil"

VIL_INFLUXDB_URL=http://host.docker.internal:8086
VIL_INFLUXDB_USERNAME=s3cr4t
VIL_INFLUXDB_PASSWORD=s3cr4t
VIL_GRAFANA_API_URL=http://host.docker.internal:8088/grafana-api

docker network inspect $NETWORK 1>/dev/null 2>/dev/null || docker network create $NETWORK

docker run -p 3000:3000 --network $NETWORK \
    -e VIL_INFLUXDB_URL=$VIL_INFLUXDB_URL \
    -e VIL_INFLUXDB_USERNAME=$VIL_INFLUXDB_USERNAME \
    -e VIL_INFLUXDB_PASSWORD=$VIL_INFLUXDB_PASSWORD \
    -e VIL_GRAFANA_API_URL=$VIL_GRAFANA_API_URL \
    ${TAG}
