#!/bin/bash
# Initializes user associations and limits for the H200 high-priority allocation.
# Usage:
# ./initialize_users_h200-hp.sh [--dry-run] [path/to/all_rt_members.csv]

set -euo pipefail

shopt -s extglob

CSV_FILE="/hpc/home/ukh/accounting/all_rt_members.csv"
CSV_ARG_SEEN=false
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run] [path/to/all_rt_members.csv]"
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

assoc_exists() {
    local user_name="$1"
    local account_name="$2"
    sacctmgr show assoc where user="$user_name" account="$account_name" format=User,Account -nP 2>/dev/null | grep -Fxq "${user_name}|${account_name}"
}

set_assoc_limits() {
    local user_name="$1"
    local account_name="$2"

    if [[ "$account_name" == *_h200_r ]]; then
        run_sacctmgr modify user name="$user_name" account="$account_name" set GrpTRES=gres/gpu=2 MaxWall=1-00:00:00
    elif [[ "$account_name" == *_h200 ]]; then
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
line_number=0

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))

    if [[ $line_number -eq 1 ]]; then
        continue
    fi

    raw_line="$(trim_field "$raw_line")"
    [[ -z "$raw_line" ]] && continue

    if [[ "$raw_line" != *,* ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    user_name="${raw_line##*,}"
    prefix_without_netid="${raw_line%,*}"

    if [[ "$prefix_without_netid" == "$raw_line" ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    project_name="${raw_line%%,*}"
    remainder_after_project="${raw_line#*,}"
    remainder_after_type="${remainder_after_project#*,}"

    if [[ "$remainder_after_project" == "$raw_line" || "$remainder_after_type" == "$remainder_after_project" ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    team_name="${remainder_after_type%%,*}"

    user_name="$(trim_field "$user_name")"
    project_name="$(trim_field "$project_name")"
    team_name="$(trim_field "$team_name")"

    if [[ -z "$user_name" || -z "$project_name" || -z "$team_name" ]]; then
        echo "Skipping malformed row $line_number in $CSV_FILE"
        continue
    fi

    case "$team_name" in
        dcc_h200_restricted)
            account_name="${project_name}_h200_r"
            ;;
        dcc_h200_unrestricted)
            account_name="${project_name}_h200"
            ;;
        *)
            continue
            ;;
    esac

    ensure_user_assoc "$user_name" "$account_name"
    add_seen_account "$account_name"
done < "$CSV_FILE"

if [[ -n "$SEEN_ACCOUNTS" ]]; then
    IFS='|' read -r -a unique_accounts <<< "$SEEN_ACCOUNTS"
    for account_name in "${unique_accounts[@]}"; do
        reconcile_account_limits "$account_name"
    done
fi

echo "User initialization complete using $CSV_FILE"
