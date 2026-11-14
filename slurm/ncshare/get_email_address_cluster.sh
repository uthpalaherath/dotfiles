#!/bin/bash
# Build a deduplicated "Full Name <email>" list for all supported cluster accounts.
# Pass -e for bare emails.

set -euo pipefail

ACCOUNTS=(
    appstate
    campbell
    catawba
    chowan
    davidson
    duke
    ecu
    elon
    guilford
    meredith
    ncat
    nccu
    ncssm
    ncsu
    unc
    uncc
    uncfsu
    uncp
    uncw
    wcu
    wfu
    wssu
)

SCRIPT_DIR="$HOME/dotfiles/slurm/ncshare"
OUTPUT_FILE="master_email_list_$(date +%F).txt"

EMAILS=$("$SCRIPT_DIR/get_email_address.sh" "$@" "${ACCOUNTS[@]}")

if [ -z "$EMAILS" ]; then
    echo "Error: no email addresses were found." >&2
    exit 1
fi

printf '%s\n' "$EMAILS" | tee "$OUTPUT_FILE"
