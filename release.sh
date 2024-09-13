#!/bin/zsh

set +x

npm install --no-save semantic-release @semantic-release/git @semantic-release/changelog

npx semantic-release $@
