#!/usr/bin/env bash
# partition_gpu_eff_weighted_simple_ordered_mem.sh
#
# For a partition + date range:
#   1) Get list of users from `slurm-report --summary --plain`
#   2) For each user, run `slurm-report --plain -u user`
#      and extract WEIGHTED row's:
#         - Elapsed (seconds)
#         - GPUEff (time-weighted % per GPU)
#         - GPUUtil (time-weighted %, ~ GPUEff * avg #GPUs)
#         - GPUMemEff (time-weighted %)
#   3) For each user, infer:
#         - avg #GPUs = GPUUtil / GPUEff  (if both >0, else 1.0)
#         - GPU-hours = Elapsed_hours * avg #GPUs
#   4) Combine users into:
#         - partition time-weighted Avg GPUEff
#         - partition Avg GPU Mem Eff
#   5) Order users by GPUEff (highest to lowest)
#
# Usage:
#   ./partition_gpu_eff_weighted_simple_ordered_mem.sh -p PARTITION -s STARTDATE -e ENDDATE
#
# Example:
#   ./partition_gpu_eff_weighted_simple_ordered_mem.sh -p h200alloc -s 2025-12-01 -e 2025-12-09

set -euo pipefail

PART="h200alloc"
START="$(date -d 'today' +%Y-%m-%d)"
END=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--partition) PART="$2"; shift 2;;
    -s|--start)     START="$2"; shift 2;;
    -e|--end)       END="$2";   shift 2;;
    -h|--help)
      echo "Usage: $0 [-p PARTITION] [-s STARTDATE] [-e ENDDATE]"
      echo "Example: $0 -p h200alloc -s 2025-12-01 -e 2025-12-09"
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# --- 1) Get user list from summary (ONLY for users) -------------------------

SUM_CMD=(slurm-report -r "$PART" -S "$START" --summary --plain)
if [[ -n "$END" ]]; then
  SUM_CMD+=(-E "$END")
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

# Extract unique users and their GPU Hours from the summary table
readarray -t USER_DATA < <(
  printf '%s\n' "$SUMMARY" |
  awk '
    BEGIN { FS = "[[:space:]]+"; in_table = 0; }
    /^[-]{2,}$/ { in_table=1; next }    # line of dashes -> start of table rows
    !in_table { next }
    NF < 1 { next }
    {
      u = $1;
      gh = $3;  # GPU Hours column is 3rd column
      if (u == "User" || u == "") next;  # skip header line / junk
      print u " " gh;
    }
  ' | sort -u
)

# Extract just usernames for the detailed report processing
readarray -t USERS < <(
  printf '%s\n' "$SUMMARY" |
  awk '
    BEGIN { FS = "[[:space:]]+"; in_table = 0; }
    /^[-]{2,}$/ { in_table=1; next }    # line of dashes -> start of table rows
    !in_table { next }
    NF < 1 { next }
    {
      u = $1;
      if (u == "User" || u == "") next;  # skip header line / junk
      print u;
    }
  ' | sort -u
)

if [[ ${#USERS[@]} -eq 0 ]]; then
  echo "No users found in summary output for partition=$PART between $START and ${END:-now}"
  exit 0
fi

  # --- 2) Create lookup table for GPU Hours from summary -------------

# Create associative array with GPU Hours from summary
declare -A USER_GPU_HOURS
for line in "${USER_DATA[@]}"; do
  read -r user gpu_hours <<< "$line"
  USER_GPU_HOURS["$user"]="$gpu_hours"
done

# --- 3) For each user, parse their WEIGHTED row from `--plain -u user` ------

BASE_CMD=(slurm-report -r "$PART" -S "$START" --plain)
if [[ -n "$END" ]]; then
  BASE_CMD+=(-E "$END")
fi

STATS=""

for u in "${USERS[@]}"; do
  USER_REPORT="$("${BASE_CMD[@]}" -u "$u" 2>/dev/null || true)"
  [[ -z "$USER_REPORT" ]] && USER_REPORT=""

  # Extract GPUEff (%), GPUUtil (%), GPUMemEff (%) from WEIGHTED row
  metrics="$(
    awk '
      BEGIN {
        gpu_eff = 0;
        gpu_util = 0;
        gpu_mem_eff = 0;
      }

      # WEIGHTED row: extract GPUEff + GPUUtil + GPUMemEff by tokens
      /^[[:space:]]*WEIGHTED[[:space:]]/ {
        line = $0;
        n = split(line, a, /[[:space:]]+/);

        # Find the elapsed time token (first time-like thing)
        t_idx = 0;
        for (i = 1; i <= n; i++) {
          if (a[i] ~ /^[0-9]+-[0-9]+:[0-9]{2}:[0-9]{2}$/ ||
              a[i] ~ /^[0-9]+:[0-9]{2}:[0-9]{2}$/ ||
              a[i] ~ /^[0-9]+:[0-9]{2}$/) {
            t_idx = i;
            break;
          }
        }

        # Collect all tokens after elapsed (kept in order, including ---)
        for (j in vals) delete vals[j];
        k = 0;
        for (i = t_idx + 1; i <= n; i++) {
          k++;
          vals[k] = a[i];
        }

        # After elapsed, WEIGHTED row layout is effectively:
        #   CPUEff, MemEff, GPUEff, GPUUtil, GPUMemEff, GPUMem
        # So GPUEff is vals[3], GPUUtil is vals[4], GPUMemEff is vals[5]
        gpueff_str = "";
        gpuutil_str = "";
        gpumemeff_str = "";

        if (k >= 3) gpueff_str = vals[3];
        if (k >= 4) gpuutil_str = vals[4];
        if (k >= 5) gpumemeff_str = vals[5];

        # GPUEff
        if (gpueff_str != "" && gpueff_str != "---" && gpueff_str ~ /%$/) {
          gsub(/%/, "", gpueff_str);
          gpu_eff = gpueff_str + 0;
        } else {
          gpu_eff = 0;
        }

        # GPUUtil
        if (gpuutil_str != "" && gpuutil_str != "---" && gpuutil_str ~ /%$/) {
          gsub(/%/, "", gpuutil_str);
          gpu_util = gpuutil_str + 0;
        } else {
          gpu_util = 0;
        }

        # GPUMemEff
        if (gpumemeff_str != "" && gpumemeff_str != "---" && gpumemeff_str ~ /%$/) {
          gsub(/%/, "", gpumemeff_str);
          gpu_mem_eff = gpumemeff_str + 0;
        } else {
          gpu_mem_eff = 0;
        }
      }

      END {
        printf "%.4f %.4f %.4f\n", gpu_eff, gpu_util, gpu_mem_eff;
      }
    ' <<< "$USER_REPORT"
  )"

  # metrics is "gpueff gpuutil gpumemeff"
  read -r gpueff gpuutil gpumemeff <<< "$metrics"

  # Use GPU hours from summary instead of calculating
  gpu_hours="${USER_GPU_HOURS[$u]}"
  STATS+="$u $gpueff $gpuutil $gpumemeff $gpu_hours"$'\n'
done

  # --- 4) Aggregate per-user stats -> partition metrics -----------------------

printf '%s\n' "$STATS" | awk -v part="$PART" -v start="$START" -v end="$END" '
  BEGIN {
    OFS = "\t";
  }
  {
    # Skip completely blank lines (this avoids the extra empty "user" row)
    if (NF < 1) next;

    user     = $1;
    ge       = $2 + 0;   # GPUEff %
    gu       = $3 + 0;   # GPUUtil %
    gme      = $4 + 0;   # GPUMemEff %
    gh       = $5 + 0;   # GPU Hours from summary

    # Always keep the user, even if no GPU hours
    user_gpueff[user]    = ge;
    user_gpuutil[user]    = gu;
    user_gpumemeff[user]  = gme;
    user_gpuhrs[user]     = gh;
    seen[user] = 1;
  }
  END {
    printf "\n";
    printf "=== Time-weighted Average GPU & Memory Efficiency ==="
    printf "\n";
    printf "\n";

    printf "Partition: %s\n", part;
    printf "Start Date: %s\n", start;
    printf "End Date:   %s\n\n", (end=="" ? "now" : end);

    printf "%-24s %-12s %-12s %-12s\n",
    "User","GPU-hours","GPU Eff (%)","GPU Mem Eff (%)";
    printf "%-24s %-12s %-12s %-12s\n",
            "------------------------","---------","-----------","---------------";

    nusers              = 0;
    total_gpuhours      = 0;
    sum_secs_gpueff     = 0;
    sum_gpuhours_gpueff = 0;
    sum_gpumemeff       = 0;

    # Process users and store data for sorting
    for (u in seen) {
      nusers++;

      ge  = user_gpueff[u];
      gu  = user_gpuutil[u];
      gme = user_gpumemeff[u];
      gh  = user_gpuhrs[u];

      sum_secs_gpueff   += gh * 3600 * ge;
      sum_gpumemeff     += gme;

      total_gpuhours      += gh;
      sum_gpuhours_gpueff += gh * ge;

      # Store user data for later sorting
      users[nusers] = u;
      user_ge[u] = ge;
      user_gme[u] = gme;
    }

    # Sort users by GPUEff (highest to lowest) using a simple bubble sort
    for (i = 1; i <= nusers; i++) {
      for (j = i + 1; j <= nusers; j++) {
        if (user_ge[users[j]] > user_ge[users[i]]) {
          temp = users[i];
          users[i] = users[j];
          users[j] = temp;
        }
      }
    }

    # Print sorted results
    for (i = 1; i <= nusers; i++) {
      u = users[i];
      printf "%-24s %-12.2f %-12.2f %-12.2f\n",
              u, user_gpuhrs[u], user_ge[u], user_gme[u];
    }

    # summary
    printf "\nNo. of users: %d\n", nusers;
    printf "Total GPU-hours: %.2f\n", total_gpuhours;

    if (total_gpuhours > 0) {
      timew_avg = sum_gpuhours_gpueff / total_gpuhours;
      printf "Partition time-weighted Avg GPU Eff: %.4f%%\n", timew_avg;
    } else {
      printf "Partition time-weighted Avg GPU Eff: n/a\n";
    }

    if (nusers > 0) {
      avg_mem_eff = sum_gpumemeff / nusers;
      printf "Partition time-weighted Avg GPU Mem Eff: %.4f%%\n", avg_mem_eff;
    } else {
      printf "Partition time-weighted Avg GPU Mem Eff: n/a\n";
    }
  }
'
