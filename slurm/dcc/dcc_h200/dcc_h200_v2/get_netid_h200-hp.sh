#!/bin/bash
# This script extracts NetIDs of users associated with H200 HP Labs accounts from a CSV file.

set -euo pipefail

shopt -s extglob

H200_HP_CSV="/hpc/home/ukh/accounting/H200-GPU-StandingPriorityAllocations.csv"

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

if [ -f "$H200_HP_CSV" ]; then
   {
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

            sacctmgr show assoc where account="${labgroup}_h200_s" format=user --noheader 2>/dev/null || true
            if is_true "$hp"; then
                sacctmgr show assoc where account="${labgroup}_h200_hp" format=user --noheader 2>/dev/null || true
            fi
        done < "$H200_HP_CSV"
    #} | awk 'NF { print $1 "@duke.edu" }' | sort -u | paste -sd ';' -
    } | awk 'NF { print $1 }' | sort -u | paste -sd '\n' -
else
   echo "Error: CSV file not found at $H200_HP_CSV" >&2
fi
