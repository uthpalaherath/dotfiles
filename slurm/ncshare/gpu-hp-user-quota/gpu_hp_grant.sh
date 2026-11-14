#!/bin/bash
# Records a new gpu-hp GPU-hour grant for a user and (re)adds the institution QoS to their association.
# The grant is stored on the association comment as gpu-hp:start=YYYY-MM-DDTHH:MM:SS,quota=<GPU-hours>
# and appended to a CSV for history. A new grant replaces the previous one.
# In place of the quota:
#   revoke  Temporarily remove the institution QoS (keeps the grant). Restore with a new grant.
#   remove  Clear the grant and the user's QoS override so the association inherits from the account
#           again. Run after the user is removed from the institution's HP group in COmanage.
# Usage: gpu_hp_grant.sh [--dry-run] [--email] [--csv path] [-a account] [-s start_date] <user> <quota_gpu_hours|revoke|remove>
#   --email        Email the user about a new grant
#   -a account     Slurm account (default: user's DefaultAccount)
#   -s start_date  YYYY-MM-DD[THH:MM:SS] (default: now)

set -euo pipefail

CSV_FILE="/data/admin/gpu-hp/gpu_hp_grants.csv"
DRY_RUN=false
EMAIL=false
account=""

# Email settings
FROM_EMAIL="info@ncshare.org"
CC_EMAIL="uthpala.herath@duke.edu,info@ncshare.org"
GUIDE_URL="https://userguide.ncshare.org/guides/gpu"
LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"
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
    echo "Usage: $0 [--dry-run] [--email] [--csv path] [-a account] [-s start_date] <user> <quota_gpu_hours|revoke|remove>"
}

positional=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --email) EMAIL=true; shift ;;
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

if [[ "$quota" != "revoke" && "$quota" != "remove" ]] && ! [[ "$quota" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
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

run() {
    if $DRY_RUN; then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

append_csv() {
    local row="$1"
    if $DRY_RUN; then
        echo "[dry-run] append to $CSV_FILE: $row"
    else
        mkdir -p "$(dirname "$CSV_FILE")"
        [[ -f "$CSV_FILE" ]] || echo "user,account,qos,start_date,quota_gpu_hours" > "$CSV_FILE"
        echo "$row" >> "$CSV_FILE"
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

email_grant() {
    local addr subject body

    addr=$(get_email_for_user "$user_name")
    if [[ -z "$addr" ]]; then
        echo "Warning: no email address in LDAP for $user_name, not emailed"
        return
    fi

    subject="NCShare gpu-hp allocation established"
    body="Dear ${user_name},

THIS IS AN AUTOMATED MESSAGE!

You have been granted a GPU-hour allocation on the NCShare gpu-hp
(high-priority) partition:

  Account: ${account}
  QoS:     ${qos}
  Start:   ${start_date}
  Quota:   ${quota} GPU-hours

To use it, submit jobs with:

    #SBATCH --partition=gpu-hp
    #SBATCH --account=${account}
    #SBATCH --qos=${qos}

Directions for using the partition:

    ${GUIDE_URL}

To check your usage and remaining GPU-hours, run from a login node:

    get_gpu_quota_user.sh

Once the quota is used up, your access to gpu-hp is paused and your
pending gpu-hp jobs are cancelled. Running jobs may be cancelled too.

Please reach out to us at info@ncshare.org if you need any assistance.

Thank you,
NCShare Team
"

    if $DRY_RUN; then
        echo "[dry-run] email to $addr: $subject"
        printf '%s\n' "$body"
    elif send_email "$addr" "$subject" "$body"; then
        echo "Emailed $user_name <$addr>: $subject"
    else
        echo "Warning: failed to email $user_name <$addr>"
    fi
}

now="$(date +%Y-%m-%dT%H:%M:%S)"

if [[ "$quota" == "revoke" ]]; then
    if [[ ",$qos_list," != *",$qos,"* ]]; then
        echo "QoS already removed: $user_name -> $account ($qos)"
    else
        echo "Revoking QoS: $user_name -> $account ($qos)"
        run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS-="$qos"
    fi
    pending=$(squeue -h -u "$user_name" -q "$qos" -t PD -o %i 2>/dev/null | xargs)
    if [[ -n "$pending" ]]; then
        echo "Cancelling pending $qos jobs: $pending"
        run scancel $pending
    fi
    append_csv "$user_name,$account,$qos,$now,revoke"
    exit 0
fi

if [[ "$quota" == "remove" ]]; then
    # gpu-hp AllowGroups uses the QoS names as Unix group names.
    if [[ " $(id -nG "$user_name") " == *" $qos "* ]]; then
        echo "Error: $user_name is still in group $qos."
        echo "Remove them from the institution's HP group in COmanage first. The change can take a few minutes to reach the cluster."
        exit 1
    fi
    [[ -n "$old_comment" ]] && echo "Clearing grant: $old_comment"
    run sacctmgr --immediate modify user where name="$user_name" account="$account" set comment=""
    echo "Clearing QoS override: $user_name -> $account (inherit from account)"
    run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS=
    append_csv "$user_name,$account,$qos,$now,remove"
    exit 0
fi

[[ -n "$old_comment" ]] && echo "Replacing previous grant: $old_comment"

echo "Setting grant: $user_name -> $account ($comment)"
run sacctmgr --immediate modify user where name="$user_name" account="$account" set comment="$comment"

if [[ ",$qos_list," == *",$qos,"* ]]; then
    echo "QoS already present: $user_name -> $account ($qos)"
else
    echo "Restoring QoS: $user_name -> $account ($qos)"
    run sacctmgr --immediate modify user where name="$user_name" account="$account" set QOS+="$qos"
fi

append_csv "$user_name,$account,$qos,$start_date,$quota"

if $EMAIL; then
    email_grant
fi
