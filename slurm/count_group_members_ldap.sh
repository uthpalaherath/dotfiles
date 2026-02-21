#!/bin/bash
# Count users in accounts and their h200/h200_hp groups from LDAP

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"

get_member_count() {
    local group="$1"
    local count
    count=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(cn=$group)" memberUid 2>/dev/null | grep "^memberUid:" | wc -l)
    echo "${count:-0}"
}

# Define accounts
ACCOUNTS=(
    "appstate"
    "campbell"
    "catawba"
    "chowan"
    "davidson"
    "duke"
    "elon"
    "guilford"
    "meredith"
    "ncat"
    "nccu"
    "ncssm"
    "ncsu"
    "unc"
    "uncc"
    "uncfsu"
    "uncp"
    "uncw"
    "wfu"
    "wssu"
)

# Define which accounts have h200_hp groups
H200_HP_ACCOUNTS="duke unc ncsu ncat uncc wssu nccu davidson uncfsu"

# Get LDAP group name for an account
get_ldap_group() {
    local account="$1"
    case "$account" in
        uncc) echo "charlotte" ;;
        uncfsu) echo "fsu" ;;
        *) echo "$account" ;;
    esac
}

# Print header
printf "%-11s %8s %8s %8s\n" "Institution" "CPU" "h200" "h200_hp"
printf "%-11s %8s %8s %8s\n" "-----------" "----" "----" "-------"

total_account=0
total_h200=0
total_h200_hp=0

for account in "${ACCOUNTS[@]}"; do
    # Get the LDAP group name (may differ from account name)
    ldap_group=$(get_ldap_group "$account")

    # Get account user count
    account_count=$(get_member_count "$ldap_group")

    # Determine h200 group name
    h200_group="${account}_h200"

    # Special cases for uncc and uncfsu
    if [ "$account" = "uncc" ]; then
        h200_group="charlotte_h200"
    elif [ "$account" = "uncfsu" ]; then
        h200_group="fsu_h200"
    fi

    h200_count=$(get_member_count "$h200_group")

    # Check if this account has h200_hp
    if [[ " $H200_HP_ACCOUNTS " =~ " $account " ]]; then
        h200_hp_group="${account}_h200_hp"

        # Special cases for uncc and uncfsu
        if [ "$account" = "uncc" ]; then
            h200_hp_group="charlotte_h200_hp"
        elif [ "$account" = "uncfsu" ]; then
            h200_hp_group="fsu_h200_hp"
        fi

        h200_hp_count=$(get_member_count "$h200_hp_group")
        total_h200_hp=$((total_h200_hp + h200_hp_count))
    else
        h200_hp_count="-"
    fi

    total_account=$((total_account + account_count))
    total_h200=$((total_h200 + h200_count))

    printf "%-11s %8s %8s %8s\n" "$account" "$account_count" "$h200_count" "$h200_hp_count"
done

printf "%-11s %8s %8s %8s\n" "-----------" "----" "----" "-------"
printf "%-11s %8s %8s %8s\n" "TOTAL" "$total_account" "$total_h200" "$total_h200_hp"
