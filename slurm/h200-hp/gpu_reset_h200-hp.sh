#!/bin/bash
# This script resets RawUsage for H200 HP QoS values and logs usage before reset.
# Usage: gpu_reset_h200-hp.sh [reset] [-H]

set -euo pipefail

shopt -s extglob

CSV_FILE="/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv"
show_hours=false

minutes_to_hours() {
    awk -v mins="$1" 'BEGIN { printf "%.2f", mins / 60 }'
}

usage() {
    echo "Usage: $0 [reset] [-H]"
    echo "-H Show reset log usage in GPU-hours instead of GPU-minutes"
}

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    value="${value##+([[:space:]])}"
    value="${value%%+([[:space:]])}"
    printf '%s' "$value"
}

load_qos_list() {
    local header_seen=false
    local name
    local labgroup
    local rtoolkits_link
    local monthly_gpu_minutes
    local hp

    if [[ ! -f "$CSV_FILE" ]]; then
        echo "Error: CSV file not found: $CSV_FILE" >&2
        exit 1
    fi

    QOS_LIST=()
    while IFS=',' read -r name labgroup rtoolkits_link _ _ _ _ _ _ _ _ monthly_gpu_minutes hp _ || [[ -n "${name:-}${labgroup:-}${rtoolkits_link:-}${monthly_gpu_minutes:-}${hp:-}" ]]; do
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
        QOS_LIST+=("${labgroup}_h200")
    done < "$CSV_FILE"

    if ! $header_seen; then
        echo "Error: CSV header not found in $CSV_FILE" >&2
        exit 1
    fi
}

reset_usage() {
    local log_dir="/hpc/home/ukh/logs/h200-hp_reset"
    mkdir -p "$log_dir"
    local timestamp
    local log_file
    local output
    local billing_set
    local billing_used
    local remaining
    local billing_set_display
    local billing_used_display
    local remaining_display
    local usage_label="Billing GPU-minutes"
    local qos

    load_qos_list

    if [[ "$show_hours" = true ]]; then
        usage_label="Billing GPU-hours"
    fi

    timestamp="$(date +%Y%m%d_%H%M%S)"
    log_file="$log_dir/gpu-reset-h200-hp-${timestamp}.log"

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "$usage_label" "Used" "Remaining" > "$log_file"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" >> "$log_file"

    for qos in "${QOS_LIST[@]}"; do
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*' || true)

        billing_set=$(printf '%s\n' "$output" | head -1)
        billing_used=$(printf '%s\n' "$output" | tail -1)

        if [[ -z "$billing_set" || -z "$billing_used" ]]; then
            echo "Warning: unable to read billing usage for $qos" | tee -a "$log_file" >&2
            continue
        fi

        remaining=$((billing_set - billing_used))

        billing_set_display="$billing_set"
        billing_used_display="$billing_used"
        remaining_display="$remaining"

        if [[ "$show_hours" = true ]]; then
            billing_set_display=$(minutes_to_hours "$billing_set")
            billing_used_display=$(minutes_to_hours "$billing_used")
            remaining_display=$(minutes_to_hours "$remaining")
        fi

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set_display" "$billing_used_display" "$remaining_display" >> "$log_file"

        echo "Resetting RawUsage for $qos"
        sacctmgr --immediate modify qos where name="$qos" set RawUsage=0
    done

    echo "Log saved to $log_file"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        reset)
            ;;
        -H)
            show_hours=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

reset_usage
