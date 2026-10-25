#!/bin/bash
# Soft-blocks gpu-hp access for users who have used their GPU-hour grant.
# Grants are read from Slurm association comments (gpu-hp:start=YYYY-MM-DDTHH:MM:SS,quota=<GPU-hours>).
# Removes the institution QoS from the user's association and cancels their pending jobs under that QoS.
# Running jobs are cancelled too when CANCEL_RUNNING=true, otherwise they finish.
# Meant to run from cron, e.g.:
#   0 * * * * /path/to/gpu_hp_enforce.sh >> /data/admin/gpu-hp/enforce.log 2>&1
# Usage: gpu_hp_enforce.sh [--dry-run]

set -uo pipefail

DRY_RUN=false
# Cancel running jobs once the quota is reached (false lets them finish and overshoot the quota).
CANCEL_RUNNING=false
LOCK_FILE="/tmp/gpu_hp_enforce.lock"

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
    echo "Usage: $0 [--dry-run]"
}

case "${1:-}" in
    "") ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
esac

# Skip this run if the previous one is still going.
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

run() {
    if $DRY_RUN; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

gpu_hours_used() {
    sacct -X -D -T -nP -u "$1" -r gpu-hp -q "$2" -S "$3" -E now --format=ElapsedRaw,AllocTRES 2>/dev/null |
        awk -F'|' '{ b = 0; if (match($2, /billing=[0-9.]+/)) b = substr($2, RSTART + 8, RLENGTH - 8); s += b * $1 } END { printf "%.2f", s / 3600 }'
}

assocs=$(sacctmgr -nP show assoc format=User,Account,QOS,Comment)
if [[ -z "$assocs" ]]; then
    echo "Error: could not read Slurm associations" >&2
    exit 1
fi

now="$(date '+%Y-%m-%d %H:%M:%S')"

while IFS='|' read -r user_name account qos_list comment; do
    [[ -z "$user_name" ]] && continue
    [[ "$comment" =~ $GRANT_RE ]] || continue
    # slurmdbd stores comments lowercased (T -> t).
    start_date="${BASH_REMATCH[1]^^}"
    quota="${BASH_REMATCH[3]}"

    qos="${ACCOUNT_QOS_MAP[$account]:-}"
    if [[ -z "$qos" ]]; then
        echo "$now WARN no gpu-hp QoS for account: $user_name -> $account"
        continue
    fi
    used=$(gpu_hours_used "$user_name" "$qos" "$start_date")
    if ! awk -v q="$quota" -v u="$used" 'BEGIN { exit !(u >= q) }'; then
        continue
    fi

    if [[ ",$qos_list," == *",$qos,"* ]]; then
        echo "$now REVOKE $user_name ($account, $qos): ${used}/${quota} GPU-hours since $start_date"
        run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS-="$qos"
    fi

    # Also catches jobs left running by a revoke from before running jobs were cancelled.
    if $CANCEL_RUNNING; then
        running=$(squeue -h -u "$user_name" -q "$qos" -t R,CF,S -o %i 2>/dev/null | xargs)
        if [[ -n "$running" ]]; then
            echo "$now CANCEL running $user_name: $running"
            run scancel $running
        fi
    fi
    pending=$(squeue -h -u "$user_name" -q "$qos" -t PD -o %i 2>/dev/null | xargs)
    if [[ -n "$pending" ]]; then
        echo "$now CANCEL pending $user_name: $pending"
        run scancel $pending
    fi
done <<< "$assocs"
