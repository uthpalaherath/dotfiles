#!/bin/bash
# This script is used to set billing limits for GPU High Priority QoS and reset usage.
# Usage:
#  To set billing limits : gpu_reset.sh set
#  To reset usage and log: gpu_reset.sh reset [-H]

show_hours=false

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
)

QOS_LIST="duke_h200_hp unc_h200_hp ncsu_h200_hp ncat_h200_hp charlotte_h200_hp wssu_h200_hp nccu_h200_hp davidson_h200_hp fsu_h200_hp"

minutes_to_hours() {
    awk -v mins="$1" 'BEGIN { printf "%.2f", mins / 60 }'
}

usage() {
    echo "Usage: $0 {set|reset} [-H]"
    echo "-H Show reset log usage in GPU-hours instead of GPU-minutes"
}

set_billing() {
    for qos in $QOS_LIST; do
        billing=${BILLING_LIMITS[$qos]}
        echo "Setting GrpTRESMins=billing=$billing for $qos"
        sacctmgr --immediate modify qos "$qos" set "GrpTRESMins=billing=$billing"
    done
}

reset_usage() {
    local log_dir="$HOME/logs/gpu-hp_reset"
    mkdir -p "$log_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$log_dir/gpu-reset-${timestamp}.log"
    local usage_label="Billing GPU-minutes"

    mkdir -p "$log_dir"

    if [ "$show_hours" = true ]; then
        usage_label="Billing GPU-hours"
    fi

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "$usage_label" "Used" "Remaining" > "$log_file"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" >> "$log_file"

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

        printf "%-20s | %-20s | %-20s | %-20s\n" "$qos" "$billing_set_display" "$billing_used_display" "$remaining_display" >> "$log_file"

        echo "Resetting RawUsage for $qos"
        sacctmgr --immediate modify qos where name="$qos" set RawUsage=0
    done

    echo "Log saved to $log_file"
}

action=""

while [ $# -gt 0 ]; do
    case "$1" in
        set|reset)
            if [ -n "$action" ]; then
                usage
                exit 1
            fi
            action="$1"
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

if [ -z "$action" ]; then
    usage
    exit 1
fi

if [ "$action" = "set" ]; then
    if [ "$show_hours" = true ]; then
        echo "Error: -H can only be used with reset"
        exit 1
    fi
    set_billing
else
    reset_usage
fi
