#!/usr/bin/env bash
# send_gpu_eff_email_jobs.sh
#
# Send emails to users with low GPU efficiency, including specific job details.
#
# Usage:
#   send_gpu_eff_email_jobs.sh -r PARTITION -S STARTDATE -E ENDDATE
#
# Example:
#   send_gpu_eff_email_jobs.sh -r h200alloc -S 2026-02-17 -E 2026-02-23

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
      echo "Example: $0 -r h200alloc -S 2026-02-17 -E 2026-02-23"
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PART" ]]; then
  echo "Error: -r PARTITION is required" >&2
  exit 1
fi

echo "Step 1: Getting time-weighted averages for all users..."

TELEGRAF_OUTPUT="$(slurm-gpu report -r "$PART" -S "$START" -E "$END" --telegraf 2>/dev/null || true)"

if [[ -z "$TELEGRAF_OUTPUT" ]]; then
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
done < <(echo "$TELEGRAF_OUTPUT")

declare -A LOW_USERS

echo "Step 2: Finding users with low GPU and GPU memory efficiency..."

for user in "${!USER_GPUEFF[@]}"; do
  gpueff="${USER_GPUEFF[$user]}"
  gpumemeff="${USER_GPUMEMEFF[$user]}"

  echo "DEBUG: Checking user=$user gpueff=$gpueff gpumemeff=$gpumemeff" >&2

  if awk -v g="$gpueff" -v t="$THRESHOLD_GPU" 'BEGIN {exit !(g < t)}' && \
     awk -v g="$gpumemeff" -v t="$THRESHOLD_GPU_MEM" 'BEGIN {exit !(g < t)}'; then
    echo "DEBUG: Adding $user to LOW_USERS" >&2
    LOW_USERS["$user"]=1
  fi
done

if [[ ${#LOW_USERS[@]} -eq 0 ]]; then
  echo "No users found with GPU efficiency < ${THRESHOLD_GPU}% AND GPU mem efficiency < ${THRESHOLD_GPU_MEM}%"
  exit 0
fi

echo "Found ${#LOW_USERS[@]} users with low GPU efficiency"

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

get_underutilizing_jobs() {
  local user="$1"
  local part="$2"
  local start="$3"
  local end="$4"

  local user_output
  user_output="$(slurm-gpu report -r "$part" -S "$start" -E "$end" --plain -u "$user" 2>/dev/null || true)"

  if [[ -z "$user_output" ]]; then
    return
  fi

  echo "$user_output" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^User ]] && continue
    [[ "$line" =~ ^-+$ ]] && continue
    [[ "$line" =~ ^\ *WEIGHTED ]] && continue

    state="$(echo "$line" | awk '{print $3}')"
    [[ "$state" == "RUNNING" || "$state" == "PENDING" || "$state" == "PREEMPTED" ]] && continue

    gpueff="$(echo "$line" | awk '{print $8}')"
    gpumemeff="$(echo "$line" | awk '{print $10}')"

    [[ "$gpueff" == "---" ]] && gpueff="0"
    [[ "$gpumemeff" == "---" ]] && gpumemeff="0"

    gpueff="${gpueff//%}"
    gpumemeff="${gpumemeff//%}"

    low_gpu=""
    low_mem=""

    if awk -v g="$gpueff" -v t="$THRESHOLD_GPU" 'BEGIN {exit !(g < t)}'; then
      low_gpu="yes"
    fi
    if awk -v g="$gpumemeff" -v t="$THRESHOLD_GPU_MEM" 'BEGIN {exit !(g < t)}'; then
      low_mem="yes"
    fi

    if [[ -n "$low_gpu" ]] || [[ -n "$low_mem" ]]; then
      echo "$line"
    fi
  done
}

send_email() {
  local to="$1"
  local subject="$2"
  local body="$3"

  echo "DEBUG: in send_email, to=$to" >&2
  echo "$body" | mailx -s "$subject" -c "$CC_EMAIL" "$to" || true
  echo "DEBUG: mailx returned for $to" >&2
}

SENT_COUNT=0
SKIP_COUNT=0

echo "Step 3: Sending emails..."

for user in "${!LOW_USERS[@]}"; do
  echo "DEBUG: Processing user=$user in email loop" >&2
  gpueff="${USER_GPUEFF[$user]}"
  gpumemeff="${USER_GPUMEMEFF[$user]}"

  email="$(get_email_for_user "$user" "$PART")"

  echo "DEBUG: email for $user = '$email'" >&2

  if [[ -z "$email" ]]; then
    echo "Skipping $user: no email found"
    ((SKIP_COUNT++))
    continue
  fi

  jobs="$(get_underutilizing_jobs "$user" "$PART" "$START" "$END")"

  echo "DEBUG: about to create email body for $user" >&2

  SUBJECT="Low GPU Utilization Alert - Partition:${PART}"

  BODY="Dear ${user},

Your time-weighted GPU efficiency for partition ${PART} during ${START} to ${END} is:
  GPUEff: ${gpueff}%
  GPUMemEff: ${gpumemeff}%

The following jobs have low GPU efficiency or GPU memory efficiency:

JobID       State       Elapsed   CPUEff  MemEff  GPUEff  GPUUtil  GPUMemEff  GPUMem
------     ---------   --------   ------  ------  ------  -------  ---------  ------
${jobs}

These jobs show GPU utilization below the threshold: GPUEff < ${THRESHOLD_GPU}% AND GPUMemEff < ${THRESHOLD_GPU_MEM}% !

To check job details, from a login node run:
sacct -j <job_id>

To assess your GPU utilization, please run the following command from a login node:
slurm-gpu report -r ${PART} -S ${START} -E ${END} -u ${user}

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
  echo "DEBUG: after send_email for $user" >&2
  ((SENT_COUNT++))
  echo "DEBUG: after SENT_COUNT++ for $user, now=$SENT_COUNT" >&2
done

echo ""
echo "Done. Emails sent: $SENT_COUNT, Skipped (no email): $SKIP_COUNT"
