#!/bin/bash
# Build a deduplicated "Full Name <email>" list from Slurm associations, resolving mail via LDAP.
# Pass -e for bare emails. Users with no LDAP mail are reported on stderr.

set -euo pipefail

EMAIL_ONLY=0
if [ "${1:-}" = "-e" ]; then
    EMAIL_ONLY=1
fi

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

# uid<TAB>mail<TAB>cn for every LDAP person with a mail attribute (cn:: values are base64)
UID_MAIL=$(ldapsearch -LLL -x -o ldif-wrap=no -H "$LDAP_HOST" -b "$BASE_DN" "(&(uid=*)(mail=*))" uid mail cn |
    awk 'function emit() { if (u && m) print u "\t" m "\t" c; u = m = c = "" }
        /^uid: /{u=$2} /^mail: /{m=$2}
        /^cn: / && c == "" {c=substr($0, 5)}
        /^cn:: / && c == "" {cmd="printf %s " $2 " | base64 -d"; cmd | getline c; close(cmd)}
        /^$/{emit()} END{emit()}')

RESULT=$(awk -v exclude="${EXCLUDE_USERS[*]}" '
    BEGIN { n = split(exclude, ex, " "); for (i = 1; i <= n; i++) skip[ex[i]] = 1 }
    NR == FNR { split($0, f, "\t"); mail[f[1]] = f[2]; name[f[1]] = f[3]; next }
    {
        split($0, f, "|"); acct = f[1]; user = f[2]
        if (user in skip) next
        if (user in mail) print "OK\t" mail[user] "\t" name[user]
        else print "MISSING\t" user " (" acct ")"
    }' <(printf '%s\n' "$UID_MAIL") <(printf '%s\n' "$ASSOCS"))

MISSING=$(printf '%s\n' "$RESULT" | awk -F'\t' '$1 == "MISSING" {print $2}' | sort -u)
# Dedupe on email; quote names containing RFC 5322 specials (e.g. "Doe, Jane")
EMAILS=$(printf '%s\n' "$RESULT" | awk -F'\t' -v email_only="$EMAIL_ONLY" '
    $1 == "OK" && !seen[tolower($2)]++ {
        mail = $2; nm = $3
        if (email_only || nm == "") { print mail; next }
        if (nm ~ /[][(),.:;<>@"\\]/) { gsub(/["\\]/, "\\\\&", nm); nm = "\"" nm "\"" }
        print nm " <" mail ">"
    }' | sort -f | paste -sd ';' -)

if [ -n "$MISSING" ]; then
    echo "Warning: $(printf '%s\n' "$MISSING" | wc -l) Slurm users have no LDAP mail:" >&2
    printf '%s\n' "$MISSING" | sed 's/^/  /' >&2
fi

if [ -z "$EMAILS" ]; then
    echo "Error: no email addresses were found." >&2
    exit 1
fi

printf '%s\n' "$EMAILS" | tee "$OUTPUT_FILE"
