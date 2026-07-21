#!/usr/bin/env bash
# partition_cpu_gpu_eff.sh
#
# Report per-user CPU, memory, GPU, and GPU-memory efficiency for a Slurm
# partition and date range, then calculate partition-level weighted averages.
#
# Processing:
#   1) Run `slurm-gpu report --summary --plain` to obtain the user list and
#      GPU-hours consumed by each user.
#   2) Run `slurm-gpu report --plain -u USER` for each user and extract the
#      following values from its WEIGHTED row:
#        - Elapsed time
#        - CPU efficiency
#        - Memory efficiency
#        - GPU efficiency
#        - GPU utilization (parsed for compatibility, but not displayed)
#        - GPU-memory efficiency
#   3) Calculate partition averages using the applicable usage duration:
#        - CPU Eff     = sum(elapsed seconds * user CPU Eff) / total elapsed
#        - Mem Eff     = sum(elapsed seconds * user Mem Eff) / total elapsed
#        - GPU Eff     = sum(elapsed hours * user GPUUtil) / total GPU-hours
#        - GPU Mem Eff = sum(GPU-hours * user GPU Mem Eff) / total GPU-hours
#
# The per-user efficiency values are already weighted by `slurm-gpu report`.
# GPUUtil retains the GPU count during that weighting, so the GPU Eff formula
# remains correct when a user runs jobs with different GPU counts. This script
# performs the additional aggregation needed for partition-level metrics.
# Users are displayed in descending order of GPU efficiency.
#
# Output modes:
#   default       Human-readable table and partition summary
#   -c, --csv     CSV table followed by the partition summary
#   -t, --telegraf  Influx line protocol suitable for Telegraf
#
# Usage:
#   partition_cpu_gpu_eff.sh [-r PARTITION] [-S STARTDATE] [-E ENDDATE]
#                            [-A ACCOUNT[,ACCOUNT...]] [-c] [--telegraf]
#
# Example:
#   partition_cpu_gpu_eff.sh -r h200alloc -S 2025-12-01 -E 2025-12-09
#   partition_cpu_gpu_eff.sh -r h200alloc -S 2025-12-01 -A acct1,acct2 -t

set -euo pipefail

PART=""
START="$(date -d 'today' +%Y-%m-%d)"
END="now"
CSV_FORMAT=""
ACCOUNT=""
TELEGRAF_FORMAT=""
# Set to 1 for direct GPU-hour weighting via GPUUtil. Set to 0 to use the
# previous user-GPUEff-by-GPU-hours calculation.
GPUUTIL_WEIGHTING=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--partition) PART="$2"; shift 2;;
    -S|--start)     START="$2"; shift 2;;
    -E|--end)       END="$2"; shift 2;;
    -A|--account)   ACCOUNT="$2"; shift 2;;
    -c|--csv)       CSV_FORMAT="1"; shift;;
    -t|--telegraf)  TELEGRAF_FORMAT="1"; shift;;
    -h|--help)
      echo "Usage: $0 [-r PARTITION] [-S STARTDATE] [-E ENDDATE] [-A ACCOUNT[,ACCOUNT...]] [-c] [--telegraf]"
      echo "Example: $0 -r h200alloc -S 2025-12-01 -E 2025-12-09 -A acct1,acct2 --telegraf"
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# --- 1) Get users and GPU-hours from the summary report ---------------------

SUM_CMD=(slurm-gpu report -r "$PART" -S "$START" --summary --plain)
if [[ -n "$END" ]]; then
  SUM_CMD+=(-E "$END")
fi
if [[ -n "$ACCOUNT" ]]; then
  SUM_CMD+=(-A "$ACCOUNT")
fi

SUMMARY="$("${SUM_CMD[@]}" 2>/dev/null || true)"

if [[ -z "$SUMMARY" ]]; then
  echo "No summary output for partition=$PART between $START and ${END:-now}"
  exit 0
fi

if printf '%s\n' "$SUMMARY" | grep -qi "No valid jobs found"; then
  echo "No valid jobs found for partition=$PART between $START and ${END:-now}"
  exit 0
fi

# The plain summary table contains User in column 1 and GPU Hours in column 3.
readarray -t USER_DATA < <(
  printf '%s\n' "$SUMMARY" |
  awk '
    BEGIN { FS = "[[:space:]]+"; in_table = 0 }
    /^[-]{2,}$/ { in_table = 1; next }
    !in_table || NF < 1 { next }
    $1 != "User" && $1 != "" { print $1 " " $3 }
  ' | sort -u
)

if [[ ${#USER_DATA[@]} -eq 0 ]]; then
  echo "No users found in summary output for partition=$PART between $START and ${END:-now}"
  exit 0
fi

declare -A USER_GPU_HOURS
USERS=()
for line in "${USER_DATA[@]}"; do
  read -r user gpu_hours <<< "$line"
  USERS+=("$user")
  USER_GPU_HOURS["$user"]="$gpu_hours"
done

# --- 2) Extract each user's WEIGHTED efficiency metrics ---------------------

BASE_CMD=(slurm-gpu report -r "$PART" -S "$START" --plain)
if [[ -n "$END" ]]; then
  BASE_CMD+=(-E "$END")
fi
if [[ -n "$ACCOUNT" ]]; then
  BASE_CMD+=(-A "$ACCOUNT")
fi

STATS=""
for u in "${USERS[@]}"; do
  USER_REPORT="$("${BASE_CMD[@]}" -u "$u" 2>/dev/null || true)"

  # Locate elapsed dynamically, then use the documented metric order after it:
  # CPUEff, MemEff, GPUEff, GPUUtil, GPUMemEff, GPUMem.
  # Output: CPUEff MemEff GPUEff GPUUtil GPUMemEff elapsed_seconds.
  metrics="$(
    awk '
      function percent(value) {
        if (value == "" || value == "---" || value !~ /%$/) return 0
        sub(/%$/, "", value)
        return value + 0
      }
      function seconds(value, parts, day, count) {
        day = 0
        if (value ~ /-/) {
          split(value, parts, "-")
          day = parts[1] + 0
          value = parts[2]
        }
        count = split(value, parts, ":")
        if (count == 3) return day * 86400 + parts[1] * 3600 + parts[2] * 60 + parts[3]
        if (count == 2) return day * 86400 + parts[1] * 60 + parts[2]
        return day * 86400
      }
      BEGIN {
        cpu_eff = mem_eff = gpu_eff = gpu_util = gpu_mem_eff = elapsed = 0
      }
      /^[[:space:]]*WEIGHTED[[:space:]]/ {
        n = split($0, fields, /[[:space:]]+/)
        elapsed_idx = 0
        for (i = 1; i <= n; i++) {
          if (fields[i] ~ /^[0-9]+-[0-9]+:[0-9][0-9]:[0-9][0-9]$/ ||
              fields[i] ~ /^[0-9]+:[0-9][0-9]:[0-9][0-9]$/ ||
              fields[i] ~ /^[0-9]+:[0-9][0-9]$/) {
            elapsed_idx = i
            break
          }
        }
        if (!elapsed_idx) next

        elapsed = seconds(fields[elapsed_idx])
        cpu_eff = percent(fields[elapsed_idx + 1])
        mem_eff = percent(fields[elapsed_idx + 2])
        gpu_eff = percent(fields[elapsed_idx + 3])
        gpu_util = percent(fields[elapsed_idx + 4])
        gpu_mem_eff = percent(fields[elapsed_idx + 5])
      }
      END {
        printf "%.4f %.4f %.4f %.4f %.4f %.0f\n", \
          cpu_eff, mem_eff, gpu_eff, gpu_util, gpu_mem_eff, elapsed
      }
    ' <<< "$USER_REPORT"
  )"

  read -r cpueff memeff gpueff gpuutil gpumemeff elapsed_seconds <<< "$metrics"
  STATS+="$u $cpueff $memeff $gpueff $gpuutil $gpumemeff $elapsed_seconds ${USER_GPU_HOURS[$u]}"$'\n'
done

# --- 3) Aggregate users into partition-level weighted averages -------------

TS_NANOS="$(date +%s%N)"

printf '%s\n' "$STATS" | awk \
  -v part="$PART" -v start="$START" -v end="$END" -v acct="$ACCOUNT" \
  -v csv="$CSV_FORMAT" -v telegraf="$TELEGRAF_FORMAT" -v ts="$TS_NANOS" \
  -v gpuutil_weighting="$GPUUTIL_WEIGHTING" '
  {
    if (NF < 1) next
    user = $1
    user_cpueff[user] = $2 + 0
    user_memeff[user] = $3 + 0
    user_gpueff[user] = $4 + 0
    user_gpuutil[user] = $5 + 0
    user_gpumemeff[user] = $6 + 0
    user_elapsed[user] = $7 + 0
    user_gpuhrs[user] = $8 + 0
    seen[user] = 1
  }
  END {
    nusers = 0
    total_elapsed = 0
    total_gpuhours = 0
    sum_cpueff = 0
    sum_memeff = 0
    sum_gpueff = 0
    sum_gpuutil = 0
    sum_gpumemeff = 0

    # CPU and memory are weighted by elapsed time. GPUUtil retains GPU count,
    # allowing GPU Eff to be aggregated directly by GPU-hours.
    for (u in seen) {
      nusers++
      elapsed = user_elapsed[u]
      gpuhrs = user_gpuhrs[u]

      total_elapsed += elapsed
      total_gpuhours += gpuhrs
      sum_cpueff += elapsed * user_cpueff[u]
      sum_memeff += elapsed * user_memeff[u]
      sum_gpueff += gpuhrs * user_gpueff[u]
      sum_gpuutil += (elapsed / 3600) * user_gpuutil[u]
      sum_gpumemeff += gpuhrs * user_gpumemeff[u]

      users[nusers] = u
      user_ge[u] = user_gpueff[u]
    }

    # Sort users by GPU efficiency, highest first.
    for (i = 1; i <= nusers; i++) {
      for (j = i + 1; j <= nusers; j++) {
        if (user_ge[users[j]] > user_ge[users[i]]) {
          temp = users[i]
          users[i] = users[j]
          users[j] = temp
        }
      }
    }

    avg_cpueff = total_elapsed > 0 ? sum_cpueff / total_elapsed : 0
    avg_memeff = total_elapsed > 0 ? sum_memeff / total_elapsed : 0
    if (total_gpuhours > 0 && gpuutil_weighting == "1") {
      avg_gpueff = sum_gpuutil / total_gpuhours
    } else {
      avg_gpueff = total_gpuhours > 0 ? sum_gpueff / total_gpuhours : 0
    }
    avg_gpumemeff = total_gpuhours > 0 ? sum_gpumemeff / total_gpuhours : 0

    # Telegraf mode emits one line and no human-readable report.
    if (telegraf == "1") {
      tagstr = "partition=" part
      if (acct != "") tagstr = tagstr ",account=" acct
      printf "slurm_gpu_partition_efficiency,%s users=%di,total_gpu_hours=%.4f,avg_cpu_eff=%.4f,avg_mem_eff=%.4f,avg_gpu_eff=%.4f,avg_gpu_mem_eff=%.4f %s\n", \
        tagstr, nusers, total_gpuhours, avg_cpueff, avg_memeff, avg_gpueff, avg_gpumemeff, ts
      exit
    }

    # Default and CSV modes share the same summary; only the table differs.
    printf "=== Time-weighted Average CPU, Memory, GPU & GPU Memory Efficiency ===\n\n"
    printf "Partition: %s\n", part
    if (acct != "") printf "Account: %s\n", acct
    printf "Start Date: %s\n", start
    printf "End Date: %s\n\n", (end == "" ? "now" : end)

    if (csv == "1") {
      printf "User,GPU-hours,CPU Eff (%%),Mem Eff (%%),GPU Eff (%%),GPU Mem Eff (%%)\n"
    } else {
      printf "%-24s %-12s %-12s %-12s %-12s %-15s\n", \
        "User", "GPU-hours", "CPU Eff (%)", "Mem Eff (%)", "GPU Eff (%)", "GPU Mem Eff (%)"
      printf "%-24s %-12s %-12s %-12s %-12s %-15s\n", \
        "------------------------", "---------", "-----------", "-----------", "-----------", "---------------"
    }

    for (i = 1; i <= nusers; i++) {
      u = users[i]
      if (csv == "1") {
        printf "%s,%.2f,%.2f,%.2f,%.2f,%.2f\n", \
          u, user_gpuhrs[u], user_cpueff[u], user_memeff[u], user_gpueff[u], user_gpumemeff[u]
      } else {
        printf "%-24s %-12.2f %-12.2f %-12.2f %-12.2f %-15.2f\n", \
          u, user_gpuhrs[u], user_cpueff[u], user_memeff[u], user_gpueff[u], user_gpumemeff[u]
      }
    }

    printf "\nNo. of users: %d\n", nusers
    printf "Total GPU-hours: %.2f\n", total_gpuhours
    if (total_elapsed > 0) {
      printf "Partition time-weighted Avg CPU Eff: %.4f%%\n", avg_cpueff
      printf "Partition time-weighted Avg Mem Eff: %.4f%%\n", avg_memeff
    } else {
      printf "Partition time-weighted Avg CPU Eff: n/a\n"
      printf "Partition time-weighted Avg Mem Eff: n/a\n"
    }
    if (total_gpuhours > 0) {
      printf "Partition time-weighted Avg GPU Eff: %.4f%%\n", avg_gpueff
      printf "Partition time-weighted Avg GPU Mem Eff: %.4f%%\n", avg_gpumemeff
    } else {
      printf "Partition time-weighted Avg GPU Eff: n/a\n"
      printf "Partition time-weighted Avg GPU Mem Eff: n/a\n"
    }
  }
'
