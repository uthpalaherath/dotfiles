#!/bin/bash
# Provisions Slurm QoS, accounts, and user associations for H200 standing priority allocations.
# Usage:
#   ./provision_h200-hp.sh [--dry-run] [path/to/H200-GPU-StandingPriorityAllocations.csv]

set -euo pipefail

shopt -s extglob

CSV_FILE="/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv"
CSV_ARG_SEEN=false
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run] [path/to/H200-GPU-StandingPriorityAllocations.csv]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Error: unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if $CSV_ARG_SEEN; then
                echo "Error: multiple CSV files provided"
                usage
                exit 1
            fi
            CSV_FILE="$1"
            CSV_ARG_SEEN=true
            shift
            ;;
    esac
done

if ! command -v sacctmgr >/dev/null 2>&1; then
    echo "Error: sacctmgr command not found in PATH"
    exit 1
fi

if ! command -v getent >/dev/null 2>&1; then
    echo "Error: getent command not found in PATH"
    exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found: $CSV_FILE"
    exit 1
fi

run_sacctmgr() {
    if $DRY_RUN; then
        printf '[dry-run] sacctmgr'
        for arg in "$@"; do
            printf ' %q' "$arg"
        done
        printf '\n'
    else
        sacctmgr --immediate "$@"
    fi
}

trim_field() {
    local value="$1"
    value="${value//$'\r'/}"
    value="${value#$'\ufeff'}"
    value="${value##+([[:space:]])}"
    value="${value%%+([[:space:]])}"
    printf '%s' "$value"
}

is_true() {
    local value
    value="$(trim_field "$1")"
    value="${value,,}"
    [[ "$value" == "true" || "$value" == "yes" || "$value" == "y" || "$value" == "1" ]]
}

qos_exists() {
    local qos_name="$1"
    sacctmgr show qos "$qos_name" format=Name -nP 2>/dev/null | grep -Fxq "$qos_name"
}

account_exists() {
    local account_name="$1"
    sacctmgr show account "$account_name" format=Account -nP 2>/dev/null | grep -Fxq "$account_name"
}

assoc_exists() {
    local user_name="$1"
    local account_name="$2"
    sacctmgr show assoc where user="$user_name" account="$account_name" format=User,Account -nP 2>/dev/null | grep -Fxq "${user_name}|${account_name}"
}

ensure_qos() {
    local qos_name="$1"
    local billing_minutes="$2"

    if qos_exists "$qos_name"; then
        echo "QoS exists: $qos_name"
    else
        echo "Creating QoS: $qos_name (billing=$billing_minutes)"
        run_sacctmgr add qos "$qos_name" priority=2000 flags+=nodecay,DenyOnLimit "GrpTRESMins=billing=$billing_minutes"
    fi

    echo "Updating QoS billing: $qos_name -> $billing_minutes"
    run_sacctmgr modify qos "$qos_name" set "GrpTRESMins=billing=$billing_minutes"
}

ensure_account() {
    local account_name="$1"
    local qos_name="$2"

    if account_exists "$account_name"; then
        echo "Account exists: $account_name"
    else
        echo "Creating account: $account_name"
        run_sacctmgr add account name="$account_name" set DefaultQOS="$qos_name" QOS="$qos_name"
    fi

    echo "Ensuring account QoS mapping: $account_name -> $qos_name"
    run_sacctmgr modify account where name="$account_name" set DefaultQOS="$qos_name"
    run_sacctmgr modify account where name="$account_name" set QOS="$qos_name"
}

set_assoc_limits() {
    local user_name="$1"
    local account_name="$2"

    if [[ "$account_name" == *_h200_s ]]; then
        run_sacctmgr modify user name="$user_name" account="$account_name" set GrpTRES=gres/gpu=2 MaxWall=2-00:00:00
    elif [[ "$account_name" == *_h200_hp ]]; then
        run_sacctmgr modify user name="$user_name" account="$account_name" set GrpTRES=gres/gpu=8
    else
        echo "Skipping limit update for unsupported account pattern: $account_name"
    fi
}

ensure_user_assoc() {
    local user_name="$1"
    local account_name="$2"

    if assoc_exists "$user_name" "$account_name"; then
        echo "Association exists: $user_name -> $account_name"
    else
        echo "Creating association: $user_name -> $account_name"
        run_sacctmgr add user "$user_name" account="$account_name"
    fi

    echo "Applying limits: $user_name -> $account_name"
    set_assoc_limits "$user_name" "$account_name"
}

get_group_users() {
    local group_name="$1"
    local group_line
    local members_field
    local member
    local seen_members

    group_line="$(getent group "$group_name" || true)"
    if [[ -z "$group_line" ]]; then
        echo "Warning: group not found: $group_name" >&2
        return 0
    fi

    IFS=':' read -r _ _ _ members_field <<< "$group_line"
    members_field="$(trim_field "$members_field")"
    [[ -z "$members_field" ]] && return 0

    seen_members=""
    IFS=',' read -r -a members <<< "$members_field"
    for member in "${members[@]}"; do
        member="$(trim_field "$member")"
        [[ -z "$member" ]] && continue

        case "|$seen_members|" in
            *"|$member|"*)
                continue
                ;;
            *)
                if [[ -z "$seen_members" ]]; then
                    seen_members="$member"
                else
                    seen_members+="|$member"
                fi
                ;;
        esac

        printf '%s\n' "$member"
    done
}

add_seen_account() {
    local account_name="$1"
    case "|$SEEN_ACCOUNTS|" in
        *"|$account_name|"*) ;;
        *)
            if [[ -z "$SEEN_ACCOUNTS" ]]; then
                SEEN_ACCOUNTS="$account_name"
            else
                SEEN_ACCOUNTS+="|$account_name"
            fi
            ;;
    esac
}

reconcile_account_limits() {
    local account_name="$1"
    local users
    local seen_users
    local user_name

    echo "Reconciling all users in account: $account_name"
    users="$(sacctmgr show assoc where account="$account_name" format=User -nP 2>/dev/null || true)"
    seen_users=""

    while IFS= read -r user_name; do
        user_name="$(trim_field "$user_name")"
        [[ -z "$user_name" ]] && continue

        case "|$seen_users|" in
            *"|$user_name|"*)
                continue
                ;;
            *)
                if [[ -z "$seen_users" ]]; then
                    seen_users="$user_name"
                else
                    seen_users+="|$user_name"
                fi
                ;;
        esac

        echo "Reapplying limits: $user_name -> $account_name"
        set_assoc_limits "$user_name" "$account_name"
    done <<< "$users"
}

SEEN_ACCOUNTS=""
header_seen=false
line_number=0

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    raw_line="$(trim_field "$raw_line")"
    [[ -z "$raw_line" ]] && continue

    IFS=',' read -r name labgroup rtoolkits_link research_unit department cell_biology biostates shared_server lab_share total_gpu_allocation monthly_gpu_hours monthly_gpu_minutes hp extra_field <<< "$raw_line"

    name="$(trim_field "$name")"
    labgroup="$(trim_field "${labgroup:-}")"
    rtoolkits_link="$(trim_field "${rtoolkits_link:-}")"
    monthly_gpu_minutes="$(trim_field "${monthly_gpu_minutes:-}")"
    hp="$(trim_field "${hp:-}")"
    extra_field="$(trim_field "${extra_field:-}")"

    if ! $header_seen; then
        if [[ "$name" == "Name" && "$labgroup" == "Labgroup" && "$rtoolkits_link" == "RToolkits Link" && "$monthly_gpu_minutes" == "Monthly GPU-minutes" && "$hp" == "HP" ]]; then
            header_seen=true
        fi
        continue
    fi

    [[ -z "$raw_line" ]] && continue

    if [[ -n "$extra_field" || -z "$labgroup" || -z "$rtoolkits_link" || -z "$monthly_gpu_minutes" || -z "$hp" ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    if ! [[ "$monthly_gpu_minutes" =~ ^[0-9]+$ ]]; then
        echo "Skipping row $line_number due to invalid Monthly GPU-minutes: $monthly_gpu_minutes"
        continue
    fi

    if [[ "$rtoolkits_link" =~ ([0-9]+)/?$ ]]; then
        project_id="${BASH_REMATCH[1]}"
    else
        echo "Skipping row $line_number in $CSV_FILE: unable to parse project id from RToolkits Link"
        continue
    fi

    qos_name="${labgroup}_h200"
    shared_account="${labgroup}_h200_s"
    hp_account="${labgroup}_h200_hp"
    shared_group="${project_id}-h200s"
    hp_group="${project_id}-h200hp"

    echo "Processing $labgroup (project $project_id)"

    ensure_qos "$qos_name" "$monthly_gpu_minutes"
    ensure_account "$shared_account" "$qos_name"

    while IFS= read -r user_name; do
        user_name="$(trim_field "$user_name")"
        [[ -z "$user_name" ]] && continue
        ensure_user_assoc "$user_name" "$shared_account"
        add_seen_account "$shared_account"
    done <<< "$(get_group_users "$shared_group")"

    if is_true "$hp"; then
        ensure_account "$hp_account" "$qos_name"

        while IFS= read -r user_name; do
            user_name="$(trim_field "$user_name")"
            [[ -z "$user_name" ]] && continue
            ensure_user_assoc "$user_name" "$hp_account"
            add_seen_account "$hp_account"
        done <<< "$(get_group_users "$hp_group")"
    else
        echo "Skipping high-priority account for $labgroup because HP=$hp"
    fi
done < "$CSV_FILE"

if ! $header_seen; then
    echo "Error: CSV header not found in $CSV_FILE"
    exit 1
fi

if [[ -n "$SEEN_ACCOUNTS" ]]; then
    IFS='|' read -r -a unique_accounts <<< "$SEEN_ACCOUNTS"
    for account_name in "${unique_accounts[@]}"; do
        reconcile_account_limits "$account_name"
    done
fi

echo "Provisioning complete using $CSV_FILE"
