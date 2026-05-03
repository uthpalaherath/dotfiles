#!/bin/bash
# This script shows the quota and usage minutes (or hours) for GPU High Priority QoS.
# Usage: get_gpu_quota.sh [-H]

show_hours=false

QOS_LIST="duke_h200_hp unc_h200_hp ncsu_h200_hp ncat_h200_hp charlotte_h200_hp wssu_h200_hp nccu_h200_hp davidson_h200_hp fsu_h200_hp"

minutes_to_hours() {
    awk -v mins="$1" 'BEGIN { printf "%.2f", (mins + 0) / 60 }'
}

get_quota() {
    if [ "$show_hours" = true ]; then
        echo "Institutional Usage (GPU-hours)"
    else
        echo "Institutional Usage (GPU-minutes)"
    fi
    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Quota" "Used" "Remaining"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"

    for qos in $QOS_LIST; do
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

        billing_set=$(echo "$output" | head -1)
        billing_used=$(echo "$output" | tail -1)
        remaining=$((billing_set - billing_used))
        billing_set_display="$billing_set"
        billing_used_display="$billing_used"
        remaining_display="$remaining"

        if [ "$show_hours" = true ]; then
            billing_set_display=$(minutes_to_hours "$billing_set")
            billing_used_display=$(minutes_to_hours "$billing_used")
            remaining_display=$(minutes_to_hours "$remaining")
        fi

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set_display" "$billing_used_display" "$remaining_display"
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
