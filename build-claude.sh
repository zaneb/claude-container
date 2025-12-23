#!/bin/bash

set -e

build_args=()
if [ "$1" = "--rebuild" ]; then
    build_args=("${build_args[@]}" --no-cache)
    shift
fi

# Ensure default base image is up-to-date
podman pull --policy=newer registry.fedoraproject.org/fedora:latest

podman build -t claude:latest --build-arg UID="$(id -ru)" --build-arg GID="$(id -rg)" "${build_args[@]}" "$(dirname "${0}")"
