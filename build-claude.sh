#!/bin/bash

set -e

podman build -t claude:latest "$(dirname "${0}")"
