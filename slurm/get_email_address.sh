#!/bin/bash
# Get group emails from LDAP. If the account is a user, return their address. If it's a group, return all member addresses separated by semicolons.
# Addresses are formatted as "Full Name <email>"; pass -e for bare emails.

usage() {
    echo "Usage: $0 [-e] <account_name> [<account_name> ...]"
    echo "   or: $0 [-e] \"group1,group2,group3\""
    echo "  -e  emails only (omit names)"
    exit 1
}

EMAIL_ONLY=0
while getopts "e" opt; do
    case "$opt" in
        e) EMAIL_ONLY=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "$1" ]; then
    usage
fi

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"

get_ldap_group() {
    local account="$1"
    case "$account" in
        uncc) echo "charlotte" ;;
        uncfsu) echo "fsu" ;;
        *) echo "$account" ;;
    esac
}

# Print "Full Name <email>" (or just the email) for a uid; nothing if it has no mail
get_user_address() {
    local entry mail name specials='[][(),.:;<>@"\\]'
    entry=$(ldapsearch -LLL -x -o ldif-wrap=no -H "$LDAP_HOST" -b "$BASE_DN" "(uid=$1)" mail cn 2>/dev/null)
    mail=$(awk '/^mail: /{print $2; exit}' <<< "$entry")
    [ -z "$mail" ] && return

    name=$(awk '/^cn: /{sub(/^cn: /, ""); print; exit}' <<< "$entry")
    if [ -z "$name" ]; then
        # Non-ASCII values are base64-encoded as "cn:: ..."
        name=$(awk '/^cn:: /{print $2; exit}' <<< "$entry" | base64 -d 2>/dev/null)
    fi

    if [ "$EMAIL_ONLY" -eq 1 ] || [ -z "$name" ]; then
        echo "$mail"
    elif [[ "$name" =~ $specials ]]; then
        # Quote names containing RFC 5322 specials (e.g. "Doe, Jane")
        name=${name//\\/\\\\}
        echo "\"${name//\"/\\\"}\" <$mail>"
    else
        echo "$name <$mail>"
    fi
}

get_emails() {
    local ACCOUNT="$1"
    local USER_ADDR

    USER_ADDR=$(get_user_address "$ACCOUNT")

    if [ -n "$USER_ADDR" ]; then
        echo "$USER_ADDR"
    else
        LDAP_GROUP=$(get_ldap_group "$ACCOUNT")
        GROUP_MEMBERS=$(ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(cn=$LDAP_GROUP)" memberUid 2>/dev/null | grep "^memberUid:" | awk '{print $2}')

        for member in $GROUP_MEMBERS; do
            get_user_address "$member"
        done
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

# Remove duplicate emails (last field) and join with semicolon
if [ ${#ALL_EMAILS[@]} -gt 0 ]; then
    printf '%s\n' "${ALL_EMAILS[@]}" | awk '!seen[tolower($NF)]++' | sort -f | paste -sd ';' -
fi
