#!/bin/bash
# This script shows the quota and usage minutes (or hours) for GPU High Priority QoS.
# Usage: get_gpu_quota.sh [-H]

set -euo pipefail

shopt -s extglob

show_hours=false

QOS_CSV="/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv"
QOS_LIST=""

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    value="${value##+([[:space:]])}"
    value="${value%%+([[:space:]])}"
    printf '%s' "$value"
}

load_qos_list() {
    if [ ! -f "$QOS_CSV" ]; then
        echo "Error: QoS CSV file not found at $QOS_CSV" >&2
        exit 1
    fi

    QOS_LIST=""
    local header_seen=false
    local name
    local labgroup
    local rtoolkits_link
    local monthly_gpu_minutes
    local hp

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

        [ -z "$labgroup" ] && continue
        QOS_LIST+="${labgroup}_h200 "
    done < "$QOS_CSV"

    if ! $header_seen; then
        echo "Error: CSV header not found in $QOS_CSV" >&2
        exit 1
    fi
}

minutes_to_hours() {
    awk -v mins="$1" 'BEGIN { printf "%.2f", mins / 60 }'
}

get_quota() {
    load_qos_list

    if [ "$show_hours" = true ]; then
        echo "Account Usage (GPU-hours)"
    else
        echo "Account Usage (GPU-minutes)"
    fi
    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Quota" "Used" "Remaining"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"

    for qos in $QOS_LIST; do
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*' || true)

        billing_set=$(echo "$output" | head -1)
        billing_used=$(echo "$output" | tail -1)
        if [ -z "$billing_set" ] || [ -z "$billing_used" ]; then
            printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "unknown" "unknown" "unknown"
            continue
        fi
        remaining=$((billing_set - billing_used))

        if [ "$show_hours" = true ]; then
            billing_set=$(minutes_to_hours "$billing_set")
            billing_used=$(minutes_to_hours "$billing_used")
            remaining=$(minutes_to_hours "$remaining")
        fi

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set" "$billing_used" "$remaining"
    done
}

case "${1:-}" in
    "")
        get_quota
        ;;
    -H)
        show_hours=true
        get_quota
        ;;
    -h|--help)
        echo "Usage: $0 [-H]"
        echo "-H Show usage in GPU-hours instead of GPU-minutes"
        exit 0
        ;;
    *)
        echo "Usage: $0 [-H]"
        exit 1
        ;;
esac
