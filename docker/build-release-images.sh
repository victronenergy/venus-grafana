#!/bin/bash

PLATFORMS="linux/armhf,linux/arm64,linux/amd64"

VER=$1

if [ "$VER" == "" ]; then
  echo "specify version (for example: develop, latest, main, 1.0)"
  exit 1
fi

OWNER=${OWNER:="victronenergy"}
TARGET=venus-grafana
DOCKERFILE="docker/Dockerfile"
BUILD_OPTS="--no-cache --pull --progress=plain"

# Always tag docker image with $VER
TAG="-t $OWNER/$TARGET:$VER"
MAJMIN=$(echo $VER | grep -Eo '[0-9]+\.[0-9]+')
# Optionally tag docker image with major.minor if $VER matches SemVer spec
[[ ! -z "$MAJMIN" ]] && TAG_MAJMIN="-t $OWNER/$TARGET:$MAJMIN"

# Note that we are invoking `docker build` from our parent directory
# with -f pointing towards our custom Dockerfile
# and trailing . to specify directory to use as a build context
# while omitting files speficied in .dockerignore from the build context
(cd .. && docker buildx build ${BUILD_OPTS} -f ${DOCKERFILE} --platform $PLATFORMS ${TAG} ${TAG_MAJMIN} --push .)
