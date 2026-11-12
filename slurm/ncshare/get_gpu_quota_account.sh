#!/bin/bash
# This script shows the quota and usage GPU-hours for GPU High Priority QoS for the user's account.
# Usage: get_gpu_quota_account.sh

declare -A ACCOUNT_QOS_MAP=(
    [duke]=duke_h200_hp
    [unc]=unc_h200_hp
    [ncsu]=ncsu_h200_hp
    [ncat]=ncat_h200_hp
    [uncc]=charlotte_h200_hp
    [wssu]=wssu_h200_hp
    [nccu]=nccu_h200_hp
    [davidson]=davidson_h200_hp
    [uncfsu]=fsu_h200_hp
)

if [[ $# -gt 0 ]]; then
    echo "Usage: $0"
    [[ "$1" == "-h" || "$1" == "--help" ]] && exit 0
    exit 1
fi

# Users may belong to multiple accounts; try the default account first, then the rest.
default_account=$(sacctmgr -nP show user "$USER" format=DefaultAccount)
accounts=$(sacctmgr -nP show assoc where user="$USER" format=Account)

user_qos=""
for account in $default_account $accounts; do
    user_qos="${ACCOUNT_QOS_MAP[$account]:-}"
    [[ -n "$user_qos" ]] && break
done

if [[ -z "$user_qos" ]]; then
    echo "No GPU QoS found for account(s): $(echo $accounts)"
    exit 1
fi

# GrpTRESMins line holds billing=<quota>(<used>), both in GPU-minutes.
read -r quota used < <(scontrol show assoc_mgr flags=qos qos="$user_qos" 2>/dev/null | grep 'GrpTRESMins=' | grep -o 'billing=[0-9]*([0-9]*)' | tr -c '0-9' ' ')

echo "Institutional Usage (GPU-hours)"
printf "%-20s | %-20s | %-20s | %-20s | %-20s\n" "QoS" "Quota" "Used" "Remaining" "Used %"
printf "%-20s-+-%-20s-+-%-20s-+-%-20s-+-%-20s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..20})"
awk -v qos="$user_qos" -v q="$quota" -v u="$used" 'BEGIN {
    pct = (q + 0 == 0) ? "N/A" : sprintf("%.2f%%", u / q * 100)
    printf "%-20s | %-20.2f | %-20.2f | %-20.2f | %-20s\n", qos, q / 60, u / 60, (q - u) / 60, pct
}'
