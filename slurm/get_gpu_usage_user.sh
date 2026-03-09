#!/bin/bash
# Get GPU usage by user for gpu and gpu-hp partitions
# Usage: ./get_gpu_usage_user.sh [-S START_DATE] [-E END_DATE]
# Default: Start: 2026-02-01, End: 2026-03-05

START="2026-02-01"
END="2026-03-05"
PARTITION_SCRIPT="./partition_gpu_eff.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -S|--start) START="$2"; shift 2;;
    -E|--end) END="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

LDAP_HOST="ldap://ncshare-com-01.ncshare.org"
BASE_DN="dc=ncshare,dc=org"

get_name() {
  ldapsearch -x -H "$LDAP_HOST" -b "$BASE_DN" "(uid=$1)" displayName 2>/dev/null | grep "^displayName:" | sed 's/displayName: //'
}

declare -A GPU_DATA
declare -A GPU_HP_DATA

get_partition_data() {
  local partition="$1"
  local outfile="$2"

  > "$outfile"
  for account in $(sacctmgr show accounts format=Account --noheader); do
    "$PARTITION_SCRIPT" -S "$START" -E "$END" -r "$partition" -A "$account" 2>/dev/null | tail -n +11 | head -n -4 | while read user hrs rest; do
      if [[ -n "$user" ]]; then
        echo "$account|$user|$hrs"
      fi
    done
  done >> "$outfile"
}

get_partition_data "gpu" "/tmp/gpu_data.txt"
get_partition_data "gpu-hp" "/tmp/gpu_hp_data.txt"

echo ""
echo "Period: $START to $END"
echo ""
echo "| Account | User | Proper Name | GPU Hours (gpu) | GPU Hours (gpu-hp) |"
echo "|---------|------|-------------|-----------------|-------------------|"

# Get list of accounts with GPU usage
accounts_with_usage=()
while IFS='|' read -r acct user hrs; do
  if [[ -n "$acct" ]]; then
    accounts_with_usage+=("$acct")
  fi
done < "/tmp/gpu_data.txt"

while IFS='|' read -r acct user hrs; do
  if [[ -n "$acct" ]]; then
    if [[ ! " ${accounts_with_usage[@]} " =~ " ${acct} " ]]; then
      accounts_with_usage+=("$acct")
    fi
  fi
done < "/tmp/gpu_hp_data.txt"

# Get all accounts and find those with no usage
all_accounts=($(sacctmgr show accounts format=Account --noheader | sort))
accounts_no_usage=()
for acct in "${all_accounts[@]}"; do
  if [[ ! " ${accounts_with_usage[@]} " =~ " ${acct} " ]]; then
    accounts_no_usage+=("$acct")
  fi
done

for account in $(sacctmgr show accounts format=Account --noheader | sort); do
  users_in_account=()

  while IFS='|' read -r acct user hrs; do
    if [[ "$acct" == "$account" ]]; then
      users_in_account+=("$user")
    fi
  done < "/tmp/gpu_data.txt"

  while IFS='|' read -r acct user hrs; do
    if [[ "$acct" == "$account" ]]; then
      if [[ ! " ${users_in_account[@]} " =~ " ${user} " ]]; then
        users_in_account+=("$user")
      fi
    fi
  done < "/tmp/gpu_hp_data.txt"

  if [[ ${#users_in_account[@]} -eq 0 ]]; then
    continue
  fi

  # Sort users by total GPU hours (gpu + gpu-hp) descending
  for user in "${users_in_account[@]}"; do
    gpu_hrs=$(grep "^$account|$user|" "/tmp/gpu_data.txt" 2>/dev/null | cut -d'|' -f3)
    gpu_hp_hrs=$(grep "^$account|$user|" "/tmp/gpu_hp_data.txt" 2>/dev/null | cut -d'|' -f3)
    gpu_hrs=${gpu_hrs:-0}
    gpu_hp_hrs=${gpu_hp_hrs:-0}
    total=$(echo "$gpu_hrs + $gpu_hp_hrs" | bc)
    echo "$user|$gpu_hrs|$gpu_hp_hrs|$total"
  done | sort -t'|' -k4 -rn | while IFS='|' read -r user gpu_hrs gpu_hp_hrs total; do
    name=$(get_name "$user")
    printf "| %s | %s | %s | %s | %s |\n" "$account" "$user" "$name" "$gpu_hrs" "$gpu_hp_hrs"
  done
done

# Print accounts with no usage
if [[ ${#accounts_no_usage[@]} -gt 0 ]]; then
  echo ""
  echo "Accounts with no GPU usage: ${accounts_no_usage[*]}"
fi
