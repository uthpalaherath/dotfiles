#!/bin/bash
# This script shows the quota and usage minutes (or hours) for GPU High Priority QoS for the user's account.
# Usage: get_gpu_quota_account.sh [-H]

show_hours=false

minutes_to_hours() {
    awk -v mins="$1" 'BEGIN { printf "%.2f", mins / 60 }'
}

declare -A QOS_ACCOUNT_MAP=(
    [duke_h200_hp]=duke
    [unc_h200_hp]=unc
    [ncsu_h200_hp]=ncsu
    [ncat_h200_hp]=ncat
    [charlotte_h200_hp]=uncc
    [wssu_h200_hp]=wssu
    [nccu_h200_hp]=nccu
    [davidson_h200_hp]=davidson
    [fsu_h200_hp]=uncfsu
)

get_quota() {
    user_account=$(sacctmgr show assoc where user="$USER" format=Account --noheader | xargs)

    if [[ -z "$user_account" ]]; then
        echo "No account found for user $USER"
        exit 1
    fi

    user_qos=""
    for qos in "${!QOS_ACCOUNT_MAP[@]}"; do
        if [[ "${QOS_ACCOUNT_MAP[$qos]}" == "$user_account" ]]; then
            user_qos="$qos"
            break
        fi
    done

    if [[ -z "$user_qos" ]]; then
        echo "No GPU QoS found for account: $user_account"
        exit 1
    fi

    if [ "$show_hours" = true ]; then
        echo "Institutional Usage (GPU-hours)"
    else
        echo "Institutional Usage (GPU-minutes)"
    fi

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Quota" "Used" "Remaining"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"

    output=$(scontrol show assoc_mgr flags=qos qos="$user_qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

    billing_set=$(echo "$output" | head -1)
    billing_used=$(echo "$output" | tail -1)
    remaining=$((billing_set - billing_used))

    if [ "$show_hours" = true ]; then
        billing_set=$(minutes_to_hours "$billing_set")
        billing_used=$(minutes_to_hours "$billing_used")
        remaining=$(minutes_to_hours "$remaining")
    fi

    printf "%-20s | %-20s | %-20s | %-20s\n" "$user_qos" "$billing_set" "$billing_used" "$remaining"
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
