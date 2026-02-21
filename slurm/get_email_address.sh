#!/bin/bash
# Get group emails from LDAP. If the account is a user, return their email. If it's a group, return all member emails separated by semicolons.

if [ -z "$1" ]; then
    echo "Usage: $0 <account_name> [<account_name> ...]"
    echo "   or: $0 \"group1,group2,group3\""
    exit 1
fi

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"

get_emails() {
    local ACCOUNT="$1"
    local EMAILS=()

    USER_EMAIL=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(uid=$ACCOUNT)" mail 2>/dev/null | grep "^mail:" | awk '{print $2}')

    if [ -n "$USER_EMAIL" ]; then
        echo "$USER_EMAIL"
    else
        GROUP_MEMBERS=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(cn=$ACCOUNT)" memberUid 2>/dev/null | grep "^memberUid:" | awk '{print $2}')

        if [ -n "$GROUP_MEMBERS" ]; then
            for member in $GROUP_MEMBERS; do
                email=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(uid=$member)" mail 2>/dev/null | grep "^mail:" | awk '{print $2}')
                if [ -n "$email" ]; then
                    EMAILS+=("$email")
                fi
            done
            printf '%s\n' "${EMAILS[@]}"
        fi
    fi
}

ALL_EMAILS=()

for arg in "$@"; do
    # Split by comma if present
    IFS=',' read -ra ACCOUNTS <<< "$arg"
    for ACCOUNT in "${ACCOUNTS[@]}"; do
        emails=$(get_emails "$ACCOUNT")
        while IFS= read -r email; do
            if [ -n "$email" ]; then
                ALL_EMAILS+=("$email")
            fi
        done <<< "$emails"
    done
done

# Remove duplicates and join with semicolon
if [ ${#ALL_EMAILS[@]} -gt 0 ]; then
    printf '%s\n' "${ALL_EMAILS[@]}" | sort -u | paste -sd ';' -
fi
