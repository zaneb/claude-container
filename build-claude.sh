#!/bin/bash

set -e

build_args=()
if [ "$1" = "--rebuild" ]; then
    build_args=("${build_args[@]}" --no-cache)
    shift
fi

buildah build -t claude:latest --pull=newer --build-arg UID="$(id -ru)" --build-arg GID="$(id -rg)" "${build_args[@]}" "$(dirname "${0}")"
