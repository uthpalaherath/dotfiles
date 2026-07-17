#!/bin/bash
# Count active users by institution using eduPersonPrincipalName domains.

set -euo pipefail

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"
ACTIVE_FILTER='(&(edupersonprincipalname=*)(uidnumber>=3000000))'
H200_HP_ACCOUNTS="duke unc ncsu ncat uncc wssu nccu davidson uncfsu"

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
    "wcu"
    "wfu"
    "wssu"
)

get_h200_group() {
    local account="$1"
    case "$account" in
        uncc) echo "charlotte_h200" ;;
        uncfsu) echo "fsu_h200" ;;
        *) echo "${account}_h200" ;;
    esac
}

get_h200_hp_group() {
    local account="$1"
    case "$account" in
        uncc) echo "charlotte_h200_hp" ;;
        uncfsu) echo "fsu_h200_hp" ;;
        *) echo "${account}_h200_hp" ;;
    esac
}

count_active_group_members() {
    local group="$1"

    ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(cn=$group)" memberUid | awk '
        NR == FNR {
            active[$1] = 1
            next
        }
        /^memberUid:/ {
            uid = $2
            if (active[uid] && !seen[uid]++) {
                count++
            }
        }
        END { print count + 0 }
    ' <(awk '{ print $1 }' <<< "$active_users") -
}

active_users=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "$ACTIVE_FILTER" uid edupersonprincipalname | awk '
    BEGIN { IGNORECASE = 1 }
    /^uid:/ { uid = $2 }
    /^edupersonprincipalname:/ && $0 !~ /orig$/ {
        eppn = $2
    }
    /^$/ { emit_record(); uid = ""; eppn = "" }
    END { emit_record() }
    function emit_record() {
        if (uid == "" || eppn == "") {
            return
        }
        split(eppn, email_parts, "@")
        domain = email_parts[length(email_parts)]
        split(domain, labels, ".")
        institution = tolower(labels[length(labels) - 1])
        if (institution != "") {
            print uid, institution
        }
    }
')

active_domains=$(awk '
    { count[$2]++ }
    END {
        for (institution in count) {
            print institution, count[institution]
        }
    }
' <<< "$active_users")

printf "%-11s %8s %8s %8s\n" "Institution" "Active" "h200" "h200_hp"
printf "%-11s %8s %8s %8s\n" "-----------" "------" "----" "-------"

total=0
total_h200=0
total_h200_hp=0
for account in "${ACCOUNTS[@]}"; do
    count=$(awk -v account="$account" '$1 == account { print $2 }' <<< "$active_domains")
    count=${count:-0}

    h200_count=$(count_active_group_members "$(get_h200_group "$account")")

    if [[ " $H200_HP_ACCOUNTS " =~ " $account " ]]; then
        h200_hp_count=$(count_active_group_members "$(get_h200_hp_group "$account")")
        total_h200_hp=$((total_h200_hp + h200_hp_count))
    else
        h200_hp_count="-"
    fi

    total=$((total + count))
    total_h200=$((total_h200 + h200_count))

    printf "%-11s %8s %8s %8s\n" "$account" "$count" "$h200_count" "$h200_hp_count"
done

printf "%-11s %8s %8s %8s\n" "-----------" "------" "----" "-------"
printf "%-11s %8s %8s %8s\n" "TOTAL" "$total" "$total_h200" "$total_h200_hp"

other_domains=$(awk '
    BEGIN {
        split("appstate campbell catawba chowan davidson duke elon guilford meredith ncat nccu ncssm ncsu unc uncc uncfsu uncp uncw wcu wfu wssu", accounts)
        for (i in accounts) {
            known[accounts[i]] = 1
        }
    }
    !known[$1] { print }
' <<< "$active_domains" | sort)

if [ -n "$other_domains" ]; then
    printf "\nOther domains found by active-user query:\n"
    awk '{ printf "%-11s %8s\n", $1, $2 }' <<< "$other_domains"
fi
