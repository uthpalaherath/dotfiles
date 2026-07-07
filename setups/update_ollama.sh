#!/usr/bin/env bash

set -euo pipefail

DOWNLOAD_URL="${OLLAMA_DOWNLOAD_URL:-https://ollama.com/download/ollama-linux-amd64.tar.zst}"
PREFIX="${OLLAMA_PREFIX:-/opt/apps/rhel9/ollama}"
MODULE_DIR="${OLLAMA_MODULE_DIR:-/opt/apps/modulefiles/ollama}"
TEMPLATE_VERSION="${OLLAMA_TEMPLATE_VERSION:-0.30.10}"
TEMPLATE_MODULEFILE="${OLLAMA_TEMPLATE_MODULEFILE:-$MODULE_DIR/$TEMPLATE_VERSION}"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'error: required command not found: %s\n' "$1" >&2
        exit 1
    fi
}

detect_version() {
    local bin="$1"
    local lib_path="$2"
    local output

    output="$(LD_LIBRARY_PATH="$lib_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$bin" --version 2>/dev/null || true)"
    printf '%s\n' "$output" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+([^[:space:]]*)?' | sed -n '1p' || true
}

require_cmd curl
require_cmd grep
require_cmd mktemp
require_cmd sed
require_cmd tar

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive="$tmp_dir/ollama-linux-amd64.tar.zst"
staging="$tmp_dir/staging"
mkdir -p "$staging"

printf 'Downloading Ollama from %s\n' "$DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" -o "$archive"

printf 'Extracting archive\n'
tar -xf "$archive" -C "$staging"

if [ ! -x "$staging/bin/ollama" ]; then
    printf 'error: archive did not contain executable bin/ollama\n' >&2
    exit 1
fi

if [ ! -d "$staging/lib" ]; then
    printf 'error: archive did not contain lib directory\n' >&2
    exit 1
fi

version="${OLLAMA_VERSION_OVERRIDE:-}"
if [ -z "$version" ]; then
    version="$(detect_version "$staging/bin/ollama" "$staging/lib:$staging/lib/ollama")"
fi

if [ -z "$version" ]; then
    printf 'error: unable to detect Ollama version from downloaded binary\n' >&2
    printf '       set OLLAMA_VERSION_OVERRIDE=<version> and rerun if needed\n' >&2
    exit 1
fi

if [ ! -r "$TEMPLATE_MODULEFILE" ]; then
    printf 'error: template modulefile is not readable: %s\n' "$TEMPLATE_MODULEFILE" >&2
    exit 1
fi

printf 'Installing Ollama %s into %s\n' "$version" "$PREFIX"
install -d -m 0755 "$PREFIX/bin" "$PREFIX/lib" "$MODULE_DIR"
install -m 0755 "$staging/bin/ollama" "$PREFIX/bin/ollama"
rm -rf "$PREFIX/lib/ollama"
cp -a "$staging/lib/." "$PREFIX/lib/"

module_tmp="$tmp_dir/modulefile"
template_version_pattern="${TEMPLATE_VERSION//./\.}"
sed "s/$template_version_pattern/$version/g" "$TEMPLATE_MODULEFILE" >"$module_tmp"

modulefile="$MODULE_DIR/$version"
install -m 0644 "$module_tmp" "$modulefile"

printf 'Updating latest modulefile symlink\n'
ln -sfn "$version" "$MODULE_DIR/latest"

printf 'Installed Ollama %s\n' "$version"
printf 'Modulefile: %s\n' "$modulefile"
printf 'Latest:     %s/latest -> %s\n' "$MODULE_DIR" "$version"
