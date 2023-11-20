#!/bin/bash

VER=develop

OWNER=${OWNER:="victronenergy"}
TARGET=venus-grafana
DOCKERFILE="docker/Dockerfile"
BUILD_OPTS="--pull --progress=plain"

TAG="$OWNER/$TARGET:${VER}"

# Note that we are invoking `docker build` from our parent directory
# with -f pointing towards our custom Dockerfile
# and trailing . to specify directory to use as a build context
# while omitting files speficied in .dockerignore from the build context
(cd .. && docker build ${BUILD_OPTS} -f ${DOCKERFILE} -t ${TAG} .)
