#!/bin/bash
# This script resets RawUsage for H200 HP QoS values and logs usage before reset.
# Usage: gpu_reset_h200-hp.sh [reset]

set -euo pipefail

CSV_FILE="/hpc/home/ukh/accounting/h200-hp-labs.csv"

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    printf '%s' "$value"
}

load_qos_list() {
    local unrestricted_account
    local line_number=0

    if [[ ! -f "$CSV_FILE" ]]; then
        echo "Error: CSV file not found: $CSV_FILE" >&2
        exit 1
    fi

    QOS_LIST=()
    while IFS=',' read -r _ unrestricted_account _ _ _; do
        line_number=$((line_number + 1))
        if [[ $line_number -eq 1 ]]; then
            continue
        fi

        unrestricted_account="$(trim_field "$unrestricted_account")"
        [[ -z "$unrestricted_account" ]] && continue
        QOS_LIST+=("$unrestricted_account")
    done < "$CSV_FILE"
}

reset_usage() {
    local log_dir="/hpc/home/ukh/logs"
    mkdir -p "$log_dir"
    local timestamp
    local log_file
    local output
    local billing_set
    local billing_used
    local remaining
    local qos

    load_qos_list

    timestamp="$(date +%Y%m%d_%H%M%S)"
    log_file="$log_dir/gpu-reset-h200-hp-${timestamp}.log"

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Billing Minutes" "Used" "Remaining" > "$log_file"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" >> "$log_file"

    for qos in "${QOS_LIST[@]}"; do
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

        billing_set=$(printf '%s\n' "$output" | head -1)
        billing_used=$(printf '%s\n' "$output" | tail -1)

        if [[ -z "$billing_set" || -z "$billing_used" ]]; then
            echo "Warning: unable to read billing usage for $qos" | tee -a "$log_file" >&2
            continue
        fi

        remaining=$((billing_set - billing_used))

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set" "$billing_used" "$remaining" >> "$log_file"

        echo "Resetting RawUsage for $qos"
        sacctmgr --immediate modify qos where name="$qos" set RawUsage=0
    done

    echo "Log saved to $log_file"
}

case "${1:-}" in
    ""|reset)
        reset_usage
        ;;
    *)
        echo "Usage: $0 [reset]"
        exit 1
        ;;
esac
