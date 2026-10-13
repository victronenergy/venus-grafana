#!/bin/bash
#
# Builds and pushes the multi-platform release image.
#
# Usage: ./build-release-images.sh [version]
#
# The version argument is optional. Without it the image is tagged after the git tag that points at HEAD
# (taken from GITHUB_REF_NAME inside a tag-triggered GitHub workflow, where the clone may be shallow),
# or `develop` when HEAD is not tagged. A SemVer version such as 1.9.0 is additionally tagged with its
# major.minor version, 1.9. An explicit argument (for example: develop, main, 1.9.0) overrides the detection.

PLATFORMS="linux/armhf,linux/arm64,linux/amd64"

VER=$1
if [ -z "$VER" ] && [ "$GITHUB_REF_TYPE" = "tag" ]; then VER=$GITHUB_REF_NAME; fi
if [ -z "$VER" ]; then VER=$(git describe --tags --exact-match 2>/dev/null); fi
VER=${VER:-develop}

OWNER=${OWNER:="victronenergy"}
TARGET=venus-grafana
DOCKERFILE="docker/Dockerfile"
BUILD_OPTS="--no-cache --pull --progress=plain"

# Always tag docker image with $VER
TAG="-t $OWNER/$TARGET:$VER"
# Additionally tag docker image with major.minor if $VER is a SemVer release version
TAG_MAJMIN=""
if [[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  TAG_MAJMIN="-t $OWNER/$TARGET:${VER%.*}"
fi

echo "building $OWNER/$TARGET:$VER${TAG_MAJMIN:+ and $OWNER/$TARGET:${VER%.*}} for $PLATFORMS"

# Note that we are invoking `docker build` from our parent directory
# with -f pointing towards our custom Dockerfile
# and trailing . to specify directory to use as a build context
# while omitting files speficied in .dockerignore from the build context
(cd .. && docker buildx build ${BUILD_OPTS} -f ${DOCKERFILE} --platform $PLATFORMS ${TAG} ${TAG_MAJMIN} --push .)
