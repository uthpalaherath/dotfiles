#!/bin/bash
# Add each NCShare institution's group members to the matching Slurm account.
# Usage:
# ./set_slurm_associations.sh [-n|--dry-run]

set -uo pipefail
DRY_RUN=0
case "${1:-}" in
    "") ;;
    -n|--dry-run) DRY_RUN=1 ;;
    *) echo "usage: ${0##*/} [-n|--dry-run]" >&2; exit 2 ;;
esac

ACCOUNTS=(
    "appstate"
    "campbell"
    "catawba"
    "chowan"
    "davidson"
    "duke"
    "ecu"
    "elon"
    "guilford"
    "meredith"
    "ncat"
    "nccu"
    "ncssm"
    "ncsu"
    "unc"
    "uncc"
    "uncfsu"
    "uncp"
    "uncw"
    "wcu"
    "wfu"
    "wssu"
)

# Role accounts that live in a managed group but belong somewhere else
SKIP_USERS=" nosg1 "

# The Unix group and the Slurm account share a name except for these two.
group_for() {
    case "$1" in
        uncc) echo "charlotte" ;;
        uncfsu) echo "fsu" ;;
        *) echo "$1" ;;
    esac
}

# Existing associations as a space-separated list of "account|user" entries.
existing=" $(sacctmgr -nP show assoc format=Account,User | awk -F'|' '$2 != ""' | tr '\n' ' ') "
if [ "$existing" = "  " ]; then
    echo "error: could not read Slurm associations, not running blind" >&2
    exit 1
fi

for account in "${ACCOUNTS[@]}"; do
    group=$(group_for "$account")

    members=$(getent group "$group" | cut -d: -f4 | tr ',' ' ')
    if [ -z "$members" ]; then
        echo "warning: group '$group' is missing or empty" >&2
        continue
    fi

    for user in $members; do
        [[ "$SKIP_USERS" == *" $user "* ]] && continue
        [[ "$existing" == *" $account|$user "* ]] && continue

        if [ "$DRY_RUN" -eq 1 ]; then
            echo "would run: sacctmgr add user $user account=$account"
        else
            echo "adding $user to $account"
            sacctmgr --immediate add user "$user" account="$account" || true
        fi
    done
done
