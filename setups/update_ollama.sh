#!/usr/bin/env bash

set -euo pipefail

DOWNLOAD_URL="${OLLAMA_DOWNLOAD_URL:-https://ollama.com/download/ollama-linux-amd64.tar.zst}"
PREFIX="${OLLAMA_PREFIX:-/opt/apps/rhel9/ollama}"
MODULE_DIR="${OLLAMA_MODULE_DIR:-/opt/apps/modulefiles/ollama}"

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

render_modulefile() {
    local version="$1"
    local output="$2"

    cat >"$output" <<EOF
#%Module1.0#####################################################################
##
## Ollama modulefile
##

proc ModulesHelp { } {
      global dotversion
        puts stderr "Ollama v$version"
}

module-whatis "Loads the Ollama module and sets environmental variables."

conflict ollama

set root $PREFIX
set port 11434

prepend-path PATH \$root/bin
prepend-path LD_LIBRARY_PATH \$root/lib
prepend-path LD_LIBRARY_PATH \$root/lib/ollama

setenv OLLAMA_HOME \$root
setenv OLLAMA_MODELS /work/\$env(USER)/.ollama/models
setenv PORT \$port
setenv OLLAMA_HOST "localhost:\$port"

if { [module-info mode load] } {
    puts stderr "Ollama v$version"
    puts stderr "Model storage: /work/\$env(USER)/.ollama/models"
}
EOF
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

printf 'Installing Ollama %s into %s\n' "$version" "$PREFIX"
install -d -m 0755 "$PREFIX/bin" "$PREFIX/lib" "$MODULE_DIR"
install -m 0755 "$staging/bin/ollama" "$PREFIX/bin/ollama"
rm -rf "$PREFIX/lib/ollama"
cp -a "$staging/lib/." "$PREFIX/lib/"

module_tmp="$tmp_dir/modulefile"
render_modulefile "$version" "$module_tmp"

modulefile="$MODULE_DIR/$version"
install -m 0644 "$module_tmp" "$modulefile"

printf 'Removing old modulefiles\n'
for existing_modulefile in "$MODULE_DIR"/*; do
    if [ "$existing_modulefile" = "$modulefile" ]; then
        continue
    fi
    rm -rf "$existing_modulefile"
done

printf 'Installed Ollama %s\n' "$version"
printf 'Modulefile: %s\n' "$modulefile"
