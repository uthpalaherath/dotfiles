#!/bin/bash
# This script shows the quota and usage minutes for GPU High Priority QoS for the user's account.
# Usage: get_gpu_quota_account.sh

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

    printf "%-20s | %-20s | %-20s | %-20s\n" "QoS" "Billing Minutes" "Used" "Remaining"
    printf "%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"

    output=$(scontrol show assoc_mgr flags=qos qos="$user_qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[^()]*([0-9]*)' | grep -o '[0-9]*')

    billing_set=$(echo "$output" | head -1)
    billing_used=$(echo "$output" | tail -1)
    remaining=$((billing_set - billing_used))

    printf "%-20s | %-20s | %-20s | %-20s\n" "$user_qos" "$billing_set" "$billing_used" "$remaining"
}

case "$1" in
    "")
        get_quota
        ;;
    -h|--help)
        echo "Usage: $0"
        exit 1
        ;;
    *)
        echo "Usage: $0"
        exit 1
        ;;
esac
