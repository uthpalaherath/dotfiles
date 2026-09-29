#!/bin/bash
# This script lists users for each lab's unrestricted/restricted H200 HP accounts.
# Usage: get_users_h200-hp.sh [csv_file]

CSV_FILE="${1:-/hpc/home/ukh/accounting/h200-hp-labs.csv}"

PARENT_WIDTH=20
ACCOUNT_WIDTH=45

get_users_for_account() {
    local account="$1"
    local users

    users=$(sacctmgr show assoc where account="$account" format=user --noheader 2>/dev/null | awk 'NF { print $1 }' | sort -u)

    if [ -z "$users" ]; then
        echo ""
        return
    fi

    echo "$users" | awk 'BEGIN { ORS="" } { if (NR > 1) printf ", "; printf "%s", $0 } END { print "" }'
}

wrap_text() {
    local text="$1"
    local width="$2"

    awk -v text="$text" -v width="$width" '
        BEGIN {
            if (length(text) == 0) {
                print ""
                exit
            }

            n = split(text, items, /, /)
            line = ""

            for (i = 1; i <= n; i++) {
                item = items[i]
                candidate = line (line == "" ? "" : ", ") item

                if (length(candidate) <= width) {
                    line = candidate
                    continue
                }

                if (line != "") {
                    print line
                }

                while (length(item) > width) {
                    print substr(item, 1, width)
                    item = substr(item, width + 1)
                }

                line = item
            }

            print line
        }
    '
}

print_wrapped_row() {
    local parent_account="$1"
    local unrestricted_users="$2"
    local restricted_users="$3"
    local i
    local max_lines=0

    local parent_lines=()
    local unrestricted_lines=()
    local restricted_lines=()

    mapfile -t parent_lines < <(wrap_text "$parent_account" "$PARENT_WIDTH")
    mapfile -t unrestricted_lines < <(wrap_text "$unrestricted_users" "$ACCOUNT_WIDTH")
    mapfile -t restricted_lines < <(wrap_text "$restricted_users" "$ACCOUNT_WIDTH")

    (( ${#parent_lines[@]} > max_lines )) && max_lines=${#parent_lines[@]}
    (( ${#unrestricted_lines[@]} > max_lines )) && max_lines=${#unrestricted_lines[@]}
    (( ${#restricted_lines[@]} > max_lines )) && max_lines=${#restricted_lines[@]}

    for ((i = 0; i < max_lines; i++)); do
        printf "%-${PARENT_WIDTH}s | %-${ACCOUNT_WIDTH}s | %-${ACCOUNT_WIDTH}s\n" \
            "${parent_lines[i]:-}" \
            "${unrestricted_lines[i]:-}" \
            "${restricted_lines[i]:-}"
    done
}

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file not found at $CSV_FILE" >&2
    exit 1
fi

printf "%-${PARENT_WIDTH}s | %-${ACCOUNT_WIDTH}s | %-${ACCOUNT_WIDTH}s\n" "Parent Account" "Unrestricted Account" "Restricted Account"
printf "%-${PARENT_WIDTH}s-+-%-${ACCOUNT_WIDTH}s-+-%-${ACCOUNT_WIDTH}s\n" \
    "$(printf -- '-%.0s' $(seq 1 "$PARENT_WIDTH"))" \
    "$(printf -- '-%.0s' $(seq 1 "$ACCOUNT_WIDTH"))" \
    "$(printf -- '-%.0s' $(seq 1 "$ACCOUNT_WIDTH"))"

while IFS=, read -r parent_account unrestricted_account restricted_account _; do
    parent_account=${parent_account#"${parent_account%%[![:space:]]*}"}
    parent_account=${parent_account%"${parent_account##*[![:space:]]}"}
    parent_account=${parent_account#$'\ufeff'}
    parent_account=${parent_account//$'\r'/}
    unrestricted_account=${unrestricted_account//$'\r'/}
    restricted_account=${restricted_account//$'\r'/}

    [ "$parent_account" = "Parent Account" ] && continue
    [ -z "$parent_account" ] && continue

    unrestricted_users=$(get_users_for_account "$unrestricted_account")
    restricted_users=$(get_users_for_account "$restricted_account")

    print_wrapped_row "$parent_account" "$unrestricted_users" "$restricted_users"
done < "$CSV_FILE"
