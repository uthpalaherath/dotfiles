#!/bin/bash
# Count active users by institution using eduPersonPrincipalName domains.

set -euo pipefail

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"
H200_HP_ACCOUNTS="duke unc ncsu ncat uncc wssu nccu davidson uncfsu"

# The directory enforces a hard server-side size limit (500 entries) that paged
# results do not bypass, so the active-user query is split into uidNumber
# windows and re-split whenever a window still trips the limit.
UID_MIN=3000000
UID_SPAN=100000

ACCOUNTS=(
    "appstate"
    "campbell"
    "catawba"
    "chowan"
    "davidson"
    "duke"
    "ecu"
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
    "chicago"
    "osu"
    "cmu"
    "upenn"
    "pitt"
    "caltech"
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

# Fetch active users whose uidNumber falls in [lo, hi]; an empty hi means
# unbounded. On LDAP_SIZELIMIT_EXCEEDED (4) the window is halved and retried,
# so the walk stays correct as the directory grows.
fetch_active_range() {
    local lo="$1" hi="$2" filter mid out rc

    filter="(&(edupersonprincipalname=*)(uidnumber>=$lo)"
    if [ -n "$hi" ]; then
        filter+="(uidnumber<=$hi)"
    fi
    filter+=")"

    set +e
    out=$(ldapsearch -x -LLL -H "$LDAP_HOST" -b "$BASE_DN" "$filter" \
        uid edupersonprincipalname 2>/dev/null)
    rc=$?
    set -e

    case "$rc" in
        0)
            [ -n "$out" ] && printf '%s\n\n' "$out"
            return 0
            ;;
        4)
            if [ -z "$hi" ]; then
                mid=$((lo + UID_SPAN))
            elif [ "$lo" -ge "$hi" ]; then
                echo "error: size limit still exceeded at uidNumber $lo" >&2
                return 1
            else
                mid=$((lo + (hi - lo) / 2))
            fi
            fetch_active_range "$lo" "$mid"
            fetch_active_range "$((mid + 1))" "$hi"
            return 0
            ;;
        *)
            echo "error: ldapsearch failed (rc=$rc) for uidNumber range ${lo}-${hi:-inf}" >&2
            return "$rc"
            ;;
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

active_users=$(fetch_active_range "$UID_MIN" "" | awk '
    BEGIN { IGNORECASE = 1 }
    /^dn:/ { emit_record(); uid = ""; eppn = ""; next }
    /^uid:/ { uid = $2 }
    /^edupersonprincipalname:/ && $0 !~ /orig$/ {
        eppn = $2
    }
    END { emit_record() }
    function emit_record() {
        if (uid == "" || eppn == "") {
            return
        }
        if (emitted[uid]++) {
            return
        }
        split(eppn, email_parts, "@")
        domain = email_parts[length(email_parts)]
        split(domain, labels, ".")
        institution = tolower(labels[length(labels) - 1])
        if (institution == "uchicago") {
            institution = "chicago"
        }
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

other_domains=$(awk -v known_list="${ACCOUNTS[*]}" '
    BEGIN {
        split(known_list, accounts, " ")
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
