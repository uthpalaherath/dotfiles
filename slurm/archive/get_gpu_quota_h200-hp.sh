#!/bin/bash
# This script shows the quota and usage minutes (or hours) for GPU High Priority QoS.
# Usage: get_gpu_quota.sh [-H]

show_hours=false

QOS_CSV="/hpc/home/ukh/accounting/h200-hp-labs.csv"
QOS_LIST=""

load_qos_list() {
    if [ ! -f "$QOS_CSV" ]; then
        echo "Error: QoS CSV file not found at $QOS_CSV" >&2
        exit 1
    fi

    QOS_LIST=""
    while IFS=, read -r _ qos _; do
        [ "$qos" = "Unrestricted Account" ] && continue
        [ -z "$qos" ] && continue
        qos=${qos//$'\r'/}
        QOS_LIST+="$qos "
    done < "$QOS_CSV"
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
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

        billing_set=$(echo "$output" | head -1)
        billing_used=$(echo "$output" | tail -1)
        remaining=$((billing_set - billing_used))

        if [ "$show_hours" = true ]; then
            billing_set=$(minutes_to_hours "$billing_set")
            billing_used=$(minutes_to_hours "$billing_used")
            remaining=$(minutes_to_hours "$remaining")
        fi

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set" "$billing_used" "$remaining"
    done
}

case "$1" in
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
