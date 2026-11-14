#!/bin/bash
# This script lists users for each lab's shared/high-priority H200 HP accounts.
# Usage: get_users_h200-hp.sh [csv_file]

set -euo pipefail

shopt -s extglob

CSV_FILE="${1:-/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv}"

LABGROUP_WIDTH=20
ACCOUNT_WIDTH=45

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

get_users_for_account() {
    local account="$1"
    local users

    users=$(sacctmgr show assoc where account="$account" format=user --noheader 2>/dev/null | awk 'NF { print $1 }' | sort -u || true)

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
    local labgroup="$1"
    local shared_users="$2"
    local hp_users="$3"
    local i
    local max_lines=0

    local labgroup_lines=()
    local shared_lines=()
    local hp_lines=()

    mapfile -t labgroup_lines < <(wrap_text "$labgroup" "$LABGROUP_WIDTH")
    mapfile -t shared_lines < <(wrap_text "$shared_users" "$ACCOUNT_WIDTH")
    mapfile -t hp_lines < <(wrap_text "$hp_users" "$ACCOUNT_WIDTH")

    (( ${#labgroup_lines[@]} > max_lines )) && max_lines=${#labgroup_lines[@]}
    (( ${#shared_lines[@]} > max_lines )) && max_lines=${#shared_lines[@]}
    (( ${#hp_lines[@]} > max_lines )) && max_lines=${#hp_lines[@]}

    for ((i = 0; i < max_lines; i++)); do
        printf "%-${LABGROUP_WIDTH}s | %-${ACCOUNT_WIDTH}s | %-${ACCOUNT_WIDTH}s\n" \
            "${labgroup_lines[i]:-}" \
            "${shared_lines[i]:-}" \
            "${hp_lines[i]:-}"
    done
}

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file not found at $CSV_FILE" >&2
    exit 1
fi

printf "%-${LABGROUP_WIDTH}s | %-${ACCOUNT_WIDTH}s | %-${ACCOUNT_WIDTH}s\n" "Labgroup" "Shared Users" "High Priority Users"
printf "%-${LABGROUP_WIDTH}s-+-%-${ACCOUNT_WIDTH}s-+-%-${ACCOUNT_WIDTH}s\n" \
    "$(printf -- '-%.0s' $(seq 1 "$LABGROUP_WIDTH"))" \
    "$(printf -- '-%.0s' $(seq 1 "$ACCOUNT_WIDTH"))" \
    "$(printf -- '-%.0s' $(seq 1 "$ACCOUNT_WIDTH"))"

header_seen=false
while IFS=, read -r name labgroup rtoolkits_link _ _ _ _ _ _ _ _ monthly_gpu_minutes hp _ || [[ -n "${name:-}${labgroup:-}${rtoolkits_link:-}${monthly_gpu_minutes:-}${hp:-}" ]]; do
    name="$(trim_field "${name:-}")"
    labgroup="$(trim_field "${labgroup:-}")"
    rtoolkits_link="$(trim_field "${rtoolkits_link:-}")"
    monthly_gpu_minutes="$(trim_field "${monthly_gpu_minutes:-}")"
    hp="$(trim_field "${hp:-}")"

    if ! $header_seen; then
        if [[ "$name" == "Name" && "$labgroup" == "Labgroup" && "$rtoolkits_link" == "RToolkits Link" && "$monthly_gpu_minutes" == "Monthly GPU-minutes" && "$hp" == "HP" ]]; then
            header_seen=true
        fi
        continue
    fi

    [ -z "$labgroup" ] && continue

    shared_users=$(get_users_for_account "${labgroup}_h200_s")
    hp_users=""
    if is_true "$hp"; then
        hp_users=$(get_users_for_account "${labgroup}_h200_hp")
    fi

    print_wrapped_row "$labgroup" "$shared_users" "$hp_users"
done < "$CSV_FILE"

if ! $header_seen; then
    echo "Error: CSV header not found in $CSV_FILE" >&2
    exit 1
fi
