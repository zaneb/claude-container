#!/bin/bash

set -e

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

build_args=()
if [ "$1" = "--rebuild" ]; then
    build_args=("${build_args[@]}" --no-cache)
    shift
fi

# Accommodate building a the container on a mac
BUILDER="buildah"
if [ "$(uname -s)" = "Darwin" ]; then
    BUILDER="podman"
fi

${BUILDER} build -t claude:latest --pull=newer --build-arg UID="$(id -ru)" --build-arg GID="$(id -rg)" "${build_args[@]}" "${root_dir}"
