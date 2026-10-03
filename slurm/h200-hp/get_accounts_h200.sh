#!/bin/bash
# Prints comma-separated H200 high-priority and shared account lists from the allocation CSV.
# Usage: get_accounts_h200.sh [csv_file]

set -euo pipefail

shopt -s extglob

CSV_FILE="${1:-/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv}"

usage() {
    echo "Usage: $0 [csv_file]"
}

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    value="${value##+([[:space:]])}"
    value="${value%%+([[:space:]])}"
    printf '%s' "$value"
}

is_true() {
    local value
    value="$(trim_field "$1")"
    value="${value,,}"
    [[ "$value" == "true" || "$value" == "yes" || "$value" == "y" || "$value" == "1" ]]
}

append_csv() {
    local current="$1"
    local value="$2"

    if [[ -z "$current" ]]; then
        printf '%s' "$value"
    else
        printf '%s,%s' "$current" "$value"
    fi
}

if [[ $# -gt 1 ]]; then
    usage
    exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found: $CSV_FILE" >&2
    exit 1
fi

header_seen=false
hp_accounts=""
shared_accounts=""

while IFS=, read -r name labgroup rtoolkits_link _ _ _ _ _ _ _ _ monthly_gpu_minutes hp _ || [[ -n "${name:-}${labgroup:-}${rtoolkits_link:-}${monthly_gpu_minutes:-}${hp:-}" ]]; do
    name="$(trim_field "${name:-}")"
    labgroup="$(trim_field "${labgroup:-}")"
    rtoolkits_link="$(trim_field "${rtoolkits_link:-}")"
    monthly_gpu_minutes="$(trim_field "${monthly_gpu_minutes:-}")"
    hp="$(trim_field "${hp:-}")"

    if ! $header_seen; then
        if [[ "$name" == "Name" && "$labgroup" == "Labgroup" && "$rtoolkits_link" == "RToolkits Link" && "$monthly_gpu_minutes" == "Monthly GPU-minutes" && "$hp" == "HP" ]]; then
            header_seen=true
        fi
        continue
    fi

    [[ -z "$labgroup" ]] && continue

    shared_accounts="$(append_csv "$shared_accounts" "${labgroup}_h200_s")"
    if is_true "$hp"; then
        hp_accounts="$(append_csv "$hp_accounts" "${labgroup}_h200_hp")"
    fi
done < "$CSV_FILE"

if ! $header_seen; then
    echo "Error: CSV header not found in $CSV_FILE" >&2
    exit 1
fi

printf 'h200-hp Accounts:\n%s\n\n' "$hp_accounts"
printf 'h200-shared Accounts:\n%s\n' "$shared_accounts"
