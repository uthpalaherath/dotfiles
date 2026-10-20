#!/bin/bash
# Records a new gpu-hp GPU-hour grant for a user and (re)adds the institution QoS to their association.
# The grant is stored on the association comment as gpu-hp:start=YYYY-MM-DDTHH:MM:SS,quota=<GPU-hours>
# and appended to a CSV for history. A new grant replaces the previous one.
# Usage: gpu_hp_grant.sh [--dry-run] [--csv path] [-a account] [-s start_date] <user> <quota_gpu_hours>
#   -a account     Slurm account (default: user's DefaultAccount)
#   -s start_date  YYYY-MM-DD[THH:MM:SS] (default: now)

set -euo pipefail

CSV_FILE="/data/admin/gpu-hp/gpu_hp_grants.csv"
DRY_RUN=false
account=""
start_date="$(date +%Y-%m-%dT%H:%M:%S)"

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

usage() {
    echo "Usage: $0 [--dry-run] [--csv path] [-a account] [-s start_date] <user> <quota_gpu_hours>"
}

positional=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --csv) CSV_FILE="$2"; shift 2 ;;
        -a) account="$2"; shift 2 ;;
        -s) start_date="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) usage; exit 1 ;;
        *) positional+=("$1"); shift ;;
    esac
done

if [[ ${#positional[@]} -ne 2 ]]; then
    usage
    exit 1
fi
user_name="${positional[0]}"
quota="${positional[1]}"

if ! [[ "$quota" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: invalid quota_gpu_hours: $quota"
    exit 1
fi

if [[ "$start_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    start_date+="T00:00:00"
fi
if ! [[ "$start_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || ! date -d "$start_date" >/dev/null 2>&1; then
    echo "Error: invalid start_date (YYYY-MM-DD[THH:MM:SS]): $start_date"
    exit 1
fi

if [[ "$user_name" =~ ^[0-9]+$ ]]; then
    user_name=$(getent passwd "$user_name" | cut -d: -f1)
fi
if [[ -z "$user_name" ]] || ! getent passwd "$user_name" >/dev/null; then
    echo "Error: unknown user: ${positional[0]}"
    exit 1
fi

if [[ -z "$account" ]]; then
    account=$(sacctmgr -nP show user "$user_name" format=DefaultAccount | xargs)
fi
qos="${ACCOUNT_QOS_MAP[$account]:-}"
if [[ -z "$qos" ]]; then
    echo "Error: no gpu-hp QoS for account: ${account:-<none>} (use -a)"
    exit 1
fi

assoc=$(sacctmgr -nP show assoc where user="$user_name" account="$account" format=QOS,Comment)
if [[ -z "$assoc" ]]; then
    echo "Error: no association: $user_name -> $account"
    exit 1
fi
qos_list="${assoc%%|*}"
old_comment="${assoc#*|}"
comment="gpu-hp:start=$start_date,quota=$quota"

[[ -n "$old_comment" ]] && echo "Replacing previous grant: $old_comment"

run() {
    if $DRY_RUN; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

echo "Setting grant: $user_name -> $account ($comment)"
run sacctmgr --immediate modify user where name="$user_name" account="$account" set comment="$comment"

if [[ ",$qos_list," == *",$qos,"* ]]; then
    echo "QoS already present: $user_name -> $account ($qos)"
else
    echo "Restoring QoS: $user_name -> $account ($qos)"
    run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS+="$qos"
fi

row="$user_name,$account,$qos,$start_date,$quota"
if $DRY_RUN; then
    echo "[dry-run] append to $CSV_FILE: $row"
else
    mkdir -p "$(dirname "$CSV_FILE")"
    [[ -f "$CSV_FILE" ]] || echo "user,account,qos,start_date,quota_gpu_hours" > "$CSV_FILE"
    echo "$row" >> "$CSV_FILE"
fi
