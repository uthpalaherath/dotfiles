#!/usr/bin/env bash
# send_gpu_eff_email.sh
#
# Send emails to users whose GPU efficiency AND GPU memory efficiency
# are both below the specified thresholds.
#
# Usage:
#   send_gpu_eff_email.sh -r PARTITION -S STARTDATE -E ENDDATE
#
# Example:
#   send_gpu_eff_email.sh -r h200alloc -S 2026-01-01 -E 2026-01-31

set -euo pipefail

PART=""
START="$(date -d 'today' +%Y-%m-%d)"
END="now"
THRESHOLD_GPU=50
THRESHOLD_GPU_MEM=50
CC_EMAIL="uthpala.herath@duke.edu"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--partition) PART="$2"; shift 2;;
    -S|--start)     START="$2"; shift 2;;
    -E|--end)       END="$2";   shift 2;;
    -h|--help)
      echo "Usage: $0 -r PARTITION -S STARTDATE -ENDDATE"
      echo "Example: $0 -r h200alloc -S 2026-01-01 -E 2026-01-31"
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PART" ]]; then
  echo "Error: -r PARTITION is required" >&2
  exit 1
fi

EFF_OUTPUT="$(slurm-gpu report -r "$PART" -S "$START" -E "$END" --telegraf -a 2>/dev/null || true)"

if [[ -z "$EFF_OUTPUT" ]]; then
  echo "No efficiency data for partition=$PART between $START and ${END:-now}"
  exit 0
fi

declare -A USER_GPUEFF
declare -A USER_GPUMEMEFF

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  user="$(echo "$line" | grep -oP 'user=\K[^,]+' || true)"
  [[ -z "$user" ]] && continue

  gpu_eff="$(echo "$line" | grep -oP 'gpu_eff=\K[0-9.]+' || echo "0")"
  gpu_mem_eff="$(echo "$line" | grep -oP 'gpu_mem_eff=\K[0-9.]+' || echo "0")"

  USER_GPUEFF["$user"]="$gpu_eff"
  USER_GPUMEMEFF["$user"]="$gpu_mem_eff"
done <<< "$EFF_OUTPUT"

get_email_for_user() {
  local user="$1"
  local part="$2"

  if [[ "$part" == "h200alloc" || "$part" == "h200ea" ]]; then
    echo "${user}@duke.edu"
  else
    local email
    email="$(./get_email_address.sh "$user" 2>/dev/null | head -1)" || true
    if [[ -n "$email" ]]; then
      echo "$email"
    fi
  fi
}

send_email() {
  local to="$1"
  local subject="$2"
  local body="$3"

  echo "$body" | mailx -s "$subject" -c "$CC_EMAIL" "$to"
}

SENT_COUNT=0
SKIP_COUNT=0

echo "Finding underutilizing users (GPU Eff < $THRESHOLD_GPU% AND GPU Mem Eff < $THRESHOLD_GPU_MEM%)..."
echo ""

for user in "${!USER_GPUEFF[@]}"; do
  gpueff="${USER_GPUEFF[$user]}"
  gpumemeff="${USER_GPUMEMEFF[$user]}"

  if (( $(echo "$gpueff < $THRESHOLD_GPU" | bc -l) )) && (( $(echo "$gpumemeff < $THRESHOLD_GPU_MEM" | bc -l) )); then
    email="$(get_email_for_user "$user" "$PART")"

    if [[ -z "$email" ]]; then
      echo "Skipping $user: no email found"
      ((SKIP_COUNT++))
      continue
    fi

    SUBJECT="Low GPU Utilization Alert - Partition:${PART}"

    BODY="Dear ${user},

Your GPU utilization on partition ${PART} is low!

Time-weighted Average GPU Efficiency: ${gpueff}% (threshold: ${THRESHOLD_GPU}%)
Time-weighted Average GPU Memory Efficiency: ${gpumemeff}% (threshold: ${THRESHOLD_GPU_MEM}%)

To assess your GPU utilization, please run the following command from a login node:
slurm-gpu report -r ${PART} -S today -E now -u ${user}

This will help you identify jobs that may be underutilizing GPU resources.
If you have any questions or need assistance optimizing your GPU usage, please feel free to reach out.

Thank you,
Uthpala

Uthpala Herath
Sr. Engagement Specialist
Research Computing & Support Services
Office of Information Technology
Duke University
"
    echo "Sending email to: $email (User: $user, GPUEff: $gpueff%, GPUMemEff: $gpumemeff%)"
    send_email "$email" "$SUBJECT" "$BODY"
    ((SENT_COUNT++))
  fi
done

echo ""
echo "Done. Emails sent: $SENT_COUNT, Skipped (no email): $SKIP_COUNT"
