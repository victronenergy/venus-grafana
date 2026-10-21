#!/bin/zsh

set +x

# GH_TOKEN is required by @semantic-release/github, fall back to the gh CLI login
export GH_TOKEN="${GH_TOKEN:-$(gh auth token)}"

pnpm install --no-lockfile semantic-release @semantic-release/git @semantic-release/changelog

pnpx semantic-release $@
