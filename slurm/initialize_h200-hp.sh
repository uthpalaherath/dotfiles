#!/bin/bash
# Initializes Slurm QoS and accounts based on the h200-hp-labs.csv file.
# Usage:
#   ./initialize_h200-hp.sh [--dry-run] [path/to/h200-hp-labs.csv]

set -euo pipefail

CSV_FILE="h200-hp-labs.csv"
CSV_ARG_SEEN=false
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run] [path/to/h200-hp-labs.csv]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if $CSV_ARG_SEEN; then
                echo "Error: multiple CSV files provided"
                usage
                exit 1
            fi
            CSV_FILE="$1"
            CSV_ARG_SEEN=true
            shift
            ;;
    esac
done

if ! command -v sacctmgr >/dev/null 2>&1; then
    echo "Error: sacctmgr command not found in PATH"
    exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found: $CSV_FILE"
    exit 1
fi

run_sacctmgr() {
    if $DRY_RUN; then
        printf '[dry-run] sacctmgr'
        for arg in "$@"; do
            printf ' %q' "$arg"
        done
        printf '\n'
    else
        sacctmgr --immediate "$@"
    fi
}

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    printf '%s' "$value"
}

qos_exists() {
    local qos_name="$1"
    sacctmgr show qos "$qos_name" format=Name -nP 2>/dev/null | grep -Fxq "$qos_name"
}

account_exists() {
    local account_name="$1"
    sacctmgr show account "$account_name" format=Account -nP 2>/dev/null | grep -Fxq "$account_name"
}

ensure_qos() {
    local qos_name="$1"
    local billing_minutes="$2"

    if qos_exists "$qos_name"; then
        echo "QoS exists: $qos_name"
    else
        echo "Creating QoS: $qos_name (billing=$billing_minutes)"
        run_sacctmgr add qos "$qos_name" priority=2000 flags+=nodecay,DenyOnLimit "GrpTRESMins=billing=$billing_minutes"
    fi

    echo "Updating QoS billing: $qos_name -> $billing_minutes"
    run_sacctmgr modify qos "$qos_name" set "GrpTRESMins=billing=$billing_minutes"
}

ensure_account() {
    local account_name="$1"
    local qos_name="$2"

    if account_exists "$account_name"; then
        echo "Account exists: $account_name"
    else
        echo "Creating account: $account_name"
        run_sacctmgr add account name="$account_name" set DefaultQOS="$qos_name" QOS="$qos_name"
    fi

    echo "Ensuring account QoS mapping: $account_name -> $qos_name"
    run_sacctmgr modify account where name="$account_name" set DefaultQOS="$qos_name"
    run_sacctmgr modify account where name="$account_name" set QOS="$qos_name"
}

line_number=0
while IFS=, read -r parent_account unrestricted_account restricted_account weekly_hours weekly_minutes; do
    line_number=$((line_number + 1))

    if [[ $line_number -eq 1 ]]; then
        continue
    fi

    unrestricted_account="$(trim_field "$unrestricted_account")"
    restricted_account="$(trim_field "$restricted_account")"
    weekly_minutes="$(trim_field "$weekly_minutes")"

    if [[ -z "$unrestricted_account" && -z "$restricted_account" ]]; then
        continue
    fi

    if [[ -z "$unrestricted_account" || -z "$restricted_account" || -z "$weekly_minutes" ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    if ! [[ "$weekly_minutes" =~ ^[0-9]+$ ]]; then
        echo "Skipping row $line_number due to invalid Weekly Quota (Minutes): $weekly_minutes"
        continue
    fi

    qos_name="$unrestricted_account"

    ensure_qos "$qos_name" "$weekly_minutes"
    ensure_account "$unrestricted_account" "$qos_name"
    ensure_account "$restricted_account" "$qos_name"
done < "$CSV_FILE"

echo "Initialization complete using $CSV_FILE"
