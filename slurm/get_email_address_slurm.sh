#!/bin/bash
# Build a deduplicated email list from Slurm associations, resolving mail via LDAP.
# Users with no LDAP mail are reported on stderr.

set -euo pipefail

ACCOUNTS=(
    appstate
    campbell
    catawba
    chowan
    davidson
    duke
    ecu
    elon
    guilford
    meredith
    ncat
    nccu
    ncssm
    ncsu
    unc
    uncc
    uncfsu
    uncp
    uncw
    wcu
    wfu
    wssu
)

# Service/test accounts to skip
EXCLUDE_USERS=(
    nosg1
    root
)

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="ou=people,dc=ncshare,dc=org"
OUTPUT_FILE="master_email_list_slurm_$(date +%F).txt"

# account|user for every user association in the listed accounts
ASSOCS=$(sacctmgr -nP show assoc account="$(IFS=,; echo "${ACCOUNTS[*]}")" format=account,user |
    awk -F'|' '$2 != ""' | sort -u)

if [ -z "$ASSOCS" ]; then
    echo "Error: no Slurm associations found." >&2
    exit 1
fi

# uid<TAB>mail for every LDAP person with a mail attribute
UID_MAIL=$(ldapsearch -LLL -x -o ldif-wrap=no -H "$LDAP_HOST" -b "$BASE_DN" "(&(uid=*)(mail=*))" uid mail |
    awk '/^uid: /{u=$2} /^mail: /{m=$2} /^$/{if (u && m) print u "\t" m; u=m=""} END{if (u && m) print u "\t" m}')

RESULT=$(awk -v exclude="${EXCLUDE_USERS[*]}" '
    BEGIN { n = split(exclude, ex, " "); for (i = 1; i <= n; i++) skip[ex[i]] = 1 }
    NR == FNR { split($0, f, "\t"); mail[f[1]] = f[2]; next }
    {
        split($0, f, "|"); acct = f[1]; user = f[2]
        if (user in skip) next
        if (user in mail) print "OK\t" mail[user]
        else print "MISSING\t" user " (" acct ")"
    }' <(printf '%s\n' "$UID_MAIL") <(printf '%s\n' "$ASSOCS"))

MISSING=$(printf '%s\n' "$RESULT" | awk -F'\t' '$1 == "MISSING" {print $2}' | sort -u)
EMAILS=$(printf '%s\n' "$RESULT" | awk -F'\t' '$1 == "OK" {print $2}' | sort -fu | paste -sd ';' -)

if [ -n "$MISSING" ]; then
    echo "Warning: $(printf '%s\n' "$MISSING" | wc -l) Slurm users have no LDAP mail:" >&2
    printf '%s\n' "$MISSING" | sed 's/^/  /' >&2
fi

if [ -z "$EMAILS" ]; then
    echo "Error: no email addresses were found." >&2
    exit 1
fi

printf '%s\n' "$EMAILS" | tee "$OUTPUT_FILE"
