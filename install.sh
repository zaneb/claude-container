#!/bin/bash

set -eu

TARGET="$1"

SERVER="https://downloads.claude.ai"
REPO="${SERVER}/claude-code-releases"
FP="31DD DE24 DDFA B679 F42D  7BD2 BAA9 29FF 1A7E CACE"

function fetch() {
    curl -fsSL --proto-redir '-all,https' --tlsv1.3 "$@"
}

function show_fingerprint() {
    gpg --batch --with-colons --fingerprint security@anthropic.com | awk -F: '/^fpr:/{print $10; exit}'
}

fetch "${SERVER}/keys/claude-code.asc" | gpg --batch --quiet --import
if [ "$(show_fingerprint)" != "${FP// /}" ]; then
    printf 'Invalid GPG key fingerprint\n' >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64)
        PLATFORM='linux-x64'
        ;;
    aarch64)
        PLATFORM='linux-arm64'
        ;;
    *)
        printf 'Unsupported architecture: %s\n' "${ARCH}" >&2
        exit 1
        ;;
esac

function version() {
    local target="$1"
    case "${target}" in
        stable | latest)
            fetch "${REPO}/${target}"
            ;;
        *)
            cat <<<"${target}"
            ;;
    esac
}

function expected_checksum() {
    local version="$1"
    local manifest

    printf 'Downloading checksum for version %s\n' "${version}" >&2
    manifest="$(fetch "${REPO}/${version}/manifest.json")"
    if ! gpg --batch --trusted-key "${FP}" --verify \
        --assert-signer "${FP// /}" \
        <(fetch "${REPO}/${version}/manifest.json.sig") \
        - <<<"${manifest}"; then
        exit 1
    fi

    jq -r ".platforms.\"${PLATFORM}\".checksum" <<<"${manifest}"
}

function verify_checksum() {
    local binary="$1"
    local version="$2"

    if [ "$(sha256sum "${binary}" | awk '{print $1}')" != "$(expected_checksum "${version}")" ]; then
        printf 'Invalid binary checksum\n' >&2
        exit 1
    fi
}

# Always use latest version as installer
LATEST_VERSION="$(version latest)"
DL_DIR="$(mktemp -d)"
INSTALL_BIN="${DL_DIR}/claude"
fetch --output-dir "${DL_DIR}" --remote-name "${REPO}/${LATEST_VERSION}/${PLATFORM}/claude"
verify_checksum "${INSTALL_BIN}" "${LATEST_VERSION}"

# Install target version
chmod +x "${INSTALL_BIN}"
"${INSTALL_BIN}" install "${TARGET}"
rm -rf "${DL_DIR}"

if [ "${TARGET}" != "latest" ]; then
    verify_checksum ~/.local/bin/claude "$(version "${TARGET}")"
fi
