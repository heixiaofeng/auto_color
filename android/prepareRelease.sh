#!/usr/bin/env bash

# Add keystore submodule for release
git submodule add --force https://gitlab-ci-token:$KEYSTORE_TOKEN@gitlab.com/woodemi-dev/keystore
