#!/bin/bash
# This script is used to set billing limits for GPU High Priority QoS and reset usage.
# Usage:
#  To set billing limits : gpu-hp_reset.sh set
#  To reset usage and log: gpu-hp_reset.sh reset

declare -A BILLING_LIMITS=(
    ["duke_h200_hp"]=216000
    ["unc_h200_hp"]=216000
    ["ncsu_h200_hp"]=216000
    ["ncat_h200_hp"]=216000
    ["charlotte_h200_hp"]=172800
    ["wssu_h200_hp"]=64800
    ["nccu_h200_hp"]=64800
    ["davidson_h200_hp"]=64800
    ["fsu_h200_hp"]=64800
    # ["duke_h200_hp"]=120
    # ["unc_h200_hp"]=120
    # ["ncsu_h200_hp"]=120
    # ["ncat_h200_hp"]=120
    # ["charlotte_h200_hp"]=120
    # ["wssu_h200_hp"]=120
    # ["nccu_h200_hp"]=120
    # ["davidson_h200_hp"]=120
    # ["fsu_h200_hp"]=120

)

QOS_LIST="duke_h200_hp unc_h200_hp ncsu_h200_hp ncat_h200_hp charlotte_h200_hp wssu_h200_hp nccu_h200_hp davidson_h200_hp fsu_h200_hp"

set_billing() {
    for qos in $QOS_LIST; do
        billing=${BILLING_LIMITS[$qos]}
        echo "Setting GrpTRESMins=billing=$billing for $qos"
        sacctmgr --immediate modify qos "$qos" set "GrpTRESMins=billing=$billing"
    done
}

reset_usage() {
    local log_dir="$HOME/logs"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$log_dir/gpu-hp_reset-${timestamp}.log"

    mkdir -p "$log_dir"

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Billing Minutes" "Used" "Remaining" > "$log_file"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" >> "$log_file"

    for qos in $QOS_LIST; do
        echo "Resetting RawUsage for $qos"
        sacctmgr --immediate modify qos where name="$qos" set RawUsage=0

        output=$(scontrol show assoc_mgr flags=qos qos="$qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

        billing_set=$(echo "$output" | head -1)
        billing_used=$(echo "$output" | tail -1)
        remaining=$((billing_set - billing_used))

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set" "$billing_used" "$remaining" >> "$log_file"
    done

    echo "Log saved to $log_file"
}

case "$1" in
    set)
        set_billing
        ;;
    reset)
        reset_usage
        ;;
    *)
        echo "Usage: $0 {set|reset}"
        exit 1
        ;;
esac
