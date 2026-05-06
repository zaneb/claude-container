#!/bin/bash

set -e

build_args=()
while [[ $# -gt 0 ]]; do
    case $1 in
    --rebuild)
        build_args+=(--no-cache)
        shift
        ;;
    --version)
        shift
        build_args+=(--build-arg VERSION="$1")
        shift
        ;;
    *)
        printf 'Invalid arg \"%s\"\n' "$1" >&2
        ;;
    esac
done

buildah build -t claude:latest --pull=newer --build-arg UID="$(id -ru)" --build-arg GID="$(id -rg)" "${build_args[@]}" "$(dirname "${0}")"
