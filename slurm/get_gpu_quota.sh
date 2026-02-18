#!/bin/bash
# This script shows the quota and usage minutes for GPU High Priority QoS.
# Usage: get_gpu_quota.sh

QOS_LIST="duke_h200_hp unc_h200_hp ncsu_h200_hp ncat_h200_hp charlotte_h200_hp wssu_h200_hp nccu_h200_hp davidson_h200_hp fsu_h200_hp"

get_quota() {
    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Billing Minutes" "Used" "Remaining"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"

    for qos in $QOS_LIST; do
        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

        billing_set=$(echo "$output" | head -1)
        billing_used=$(echo "$output" | tail -1)
        remaining=$((billing_set - billing_used))

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set" "$billing_used" "$remaining"
    done
}

case "$1" in
    "")
        get_quota
        ;;
    -h|--help)
        echo "Usage: $0 {set|reset}"
        exit 1
        ;;
    *)
        echo "Usage: $0 {set|reset}"
        exit 1
        ;;
esac
