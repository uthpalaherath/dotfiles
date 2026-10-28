#!/bin/bash
# Soft-blocks gpu-hp access for users who have used their GPU-hour grant.
# Grants are read from Slurm association comments (gpu-hp:start=YYYY-MM-DDTHH:MM:SS,quota=<GPU-hours>).
# Removes the institution QoS from the user's association and cancels their pending jobs under that QoS.
# Running jobs are cancelled too when CANCEL_RUNNING=true, otherwise they finish.
# The user is emailed once, when their access is revoked.
# Meant to run from cron, e.g.:
#   0 * * * * /path/to/gpu_hp_enforce.sh >> /data/admin/gpu-hp/enforce.log 2>&1
# Usage: gpu_hp_enforce.sh [--dry-run]

set -uo pipefail

DRY_RUN=false
# Cancel running jobs once the quota is reached (false lets them finish and overshoot the quota).
CANCEL_RUNNING=true
LOCK_FILE="/tmp/gpu_hp_enforce.lock"

# Email settings.
FROM_EMAIL="info@ncshare.org"
CC_EMAIL="uthpala.herath@duke.edu,info@ncshare.org"
LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"

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

# LDAP mail address for a uid, or nothing.
get_email_for_user() {
    ldapsearch -LLL -x -o ldif-wrap=no -H "$LDAP_HOST" -b "$BASE_DN" "(uid=$1)" mail 2>/dev/null |
        awk '/^mail: /{ print $2; exit }'
}

send_email() {
    local to="$1" subject="$2" body="$3"
    local args=(-r "$FROM_EMAIL" -a "From: $FROM_EMAIL")
    [[ -n "$CC_EMAIL" ]] && args+=(-a "Cc: $CC_EMAIL")
    printf '%s\n' "$body" | mailx "${args[@]}" -s "$subject" "$to"
}

# Tell the user their grant is used up. Arguments: user account qos quota used start cancelled_jobs
email_quota_reached() {
    local user="$1" account="$2" qos="$3" quota="$4" used="$5" start="$6" cancelled="$7"
    local addr subject body cancel_note=""

    addr=$(get_email_for_user "$user")
    if [[ -z "$addr" ]]; then
        echo "$now WARN no email address in LDAP for $user"
        return
    fi

    if [[ -n "$cancelled" ]]; then
        cancel_note="
Your remaining jobs under ${qos} were cancelled: ${cancelled}
"
    fi

    subject="NCShare gpu-hp GPU-hour quota reached"
    body="Dear ${user},

THIS IS AN AUTOMATED MESSAGE!

You have used the GPU-hours in your gpu-hp allocation:

  Account: ${account}
  QoS:     ${qos}
  Start:   ${start}
  Quota:   ${quota} GPU-hours
  Used:    ${used} GPU-hours

Your access to the gpu-hp partition has been paused.
${cancel_note}
You can still run jobs on the gpu and interactive-gpu partitions.

To continue using gpu-hp, ask your institutional representative for an
extension of your GPU-hour quota or a renewal of your allocation.

Please reach out to us at info@ncshare.org if you need any assistance.

Thank you,
NCShare Team
"

    if $DRY_RUN; then
        echo "[dry-run] email to $addr: $subject"
        printf '%s\n' "$body"
    elif send_email "$addr" "$subject" "$body"; then
        echo "$now EMAIL $user <$addr>: $subject"
    else
        echo "$now WARN failed to email $user <$addr>"
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

    revoked_now=false
    if [[ ",$qos_list," == *",$qos,"* ]]; then
        echo "$now REVOKE $user_name ($account, $qos): ${used}/${quota} GPU-hours since $start_date"
        run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS-="$qos"
        revoked_now=true
    fi

    # Also catches jobs left running by a revoke from before running jobs were cancelled.
    running=""
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

    if $revoked_now; then
        email_quota_reached "$user_name" "$account" "$qos" "$quota" "$used" "$start_date" "$(echo $running $pending)"
    fi
done <<< "$assocs"
