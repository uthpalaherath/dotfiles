#!/bin/bash
# This script shows gpu-hp GPU-hour grants, usage since each grant start, and remaining hours
# for users in the accounts the caller coordinates (institutional coordinator view).
# Grants are stored on Slurm association comments as gpu-hp:start=YYYY-MM-DDTHH:MM:SS,quota=<GPU-hours>.
# Usage: get_gpu_quota_user_coord.sh [-u user]
#   -u user  Show only this user's grant

target_user=""

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

GRANT_RE='^gpu-hp:start=([0-9]{4}-[0-9]{2}-[0-9]{2}([Tt][0-9]{2}:[0-9]{2}:[0-9]{2})?),quota=([0-9]+([.][0-9]+)?)$'

usage() {
    echo "Usage: $0 [-u user]"
    echo "-u user  Show only this user's grant"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u)
            [[ -z "${2:-}" ]] && { usage; exit 1; }
            target_user="$2"
            shift 2
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
done

# Institution accounts the caller coordinates.
coord_accounts=()
IFS=',' read -r -a coordinated <<< "$(sacctmgr -nP show user "$USER" withcoord format=Coordinators 2>/dev/null)"
for account in "${coordinated[@]}"; do
    [[ -n "${ACCOUNT_QOS_MAP[$account]:-}" ]] && coord_accounts+=("$account")
done

if [[ ${#coord_accounts[@]} -eq 0 ]]; then
    echo "$USER is not a coordinator of any institutional account"
    exit 1
fi
account_list=$(IFS=','; echo "${coord_accounts[*]}")

# GPU-hours on gpu-hp under the given QoS since start (billing = GPUs on gpu-hp).
gpu_hours_used() {
    sacct -X -D -T -nP -u "$1" -r gpu-hp -q "$2" -S "$3" -E now --format=ElapsedRaw,AllocTRES 2>/dev/null |
        awk -F'|' '{ b = 0; if (match($2, /billing=[0-9.]+/)) b = substr($2, RSTART + 8, RLENGTH - 8); s += b * $1 } END { printf "%.2f", s / 3600 }'
}

print_row() {
    printf "%-24s | %-10s | %-19s | %-10s | %-10s | %-10s | %-8s | %-8s\n" "$@"
}

if [[ -n "$target_user" ]]; then
    assocs=$(sacctmgr -nP show assoc where account="$account_list" user="$target_user" format=User,Account,QOS,Comment 2>/dev/null)
else
    assocs=$(sacctmgr -nP show assoc where account="$account_list" format=User,Account,QOS,Comment 2>/dev/null)
fi

found=false

while IFS='|' read -r user_name account qos_list comment; do
    [[ -z "$user_name" ]] && continue
    [[ "$comment" =~ $GRANT_RE ]] || continue
    # slurmdbd stores comments lowercased (T -> t).
    start_date="${BASH_REMATCH[1]^^}"
    quota="${BASH_REMATCH[3]}"
    qos="${ACCOUNT_QOS_MAP[$account]:-}"
    [[ -z "$qos" ]] && continue

    if ! $found; then
        echo "gpu-hp Grant Usage (GPU-hours) for account(s): ${account_list//,/, }"
        print_row "User" "Account" "Start" "Quota" "Used" "Remaining" "Used %" "Access"
        printf -- '-%.0s' {1..124}; echo
        found=true
    fi

    used=$(gpu_hours_used "$user_name" "$qos" "$start_date")
    remaining=$(awk -v q="$quota" -v u="$used" 'BEGIN { printf "%.2f", q - u }')
    percent=$(awk -v q="$quota" -v u="$used" 'BEGIN { if ((q + 0) == 0) printf "N/A"; else printf "%.2f%%", (u / q) * 100 }')
    if [[ ",$qos_list," == *",$qos,"* ]]; then
        access="active"
    else
        access="revoked"
    fi

    print_row "$user_name" "$account" "$start_date" "$quota" "$used" "$remaining" "$percent" "$access"
done <<< "$assocs"

if ! $found; then
    if [[ -n "$target_user" ]]; then
        echo "No gpu-hp grant found for $target_user in account(s): ${account_list//,/, }"
    else
        echo "No gpu-hp grants found in account(s): ${account_list//,/, }"
    fi
    exit 1
fi
