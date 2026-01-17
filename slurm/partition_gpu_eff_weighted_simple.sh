#!/usr/bin/env bash
# partition_gpu_eff_weighted.sh
#
# For a partition + date range:
#   1) Get list of users from `slurm-report --summary --plain`
#   2) For each user, run `slurm-report --plain -u user`
#      and extract the WEIGHTED row's:
#         - Elapsed (seconds)
#         - GPUEff (time-weighted % per GPU)
#         - GPUUtil (time-weighted %, ~ GPUEff * avg #GPUs)
#   3) For each user, infer:
#         - avg #GPUs = GPUUtil / GPUEff  (if both >0, else 1.0)
#         - GPU-hours = Elapsed_hours * avg #GPUs
#   4) Combine users into:
#         - partition time-weighted Avg GPUEff
#         - partition GPU-hour-weighted Avg GPUEff
#
# Usage:
#   ./partition_gpu_eff_weighted.sh -p PARTITION -s STARTDATE -e ENDDATE
#
# Example:
#   ./partition_gpu_eff_weighted.sh -p h200alloc -s 2025-12-01 -e 2025-12-09

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

# Extract unique users from the summary table (first column after the header separator)
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

# --- 2) For each user, parse their WEIGHTED row from `--plain -u user` ------

BASE_CMD=(slurm-report -r "$PART" -S "$START" --plain)
if [[ -n "$END" ]]; then
  BASE_CMD+=(-E "$END")
fi

STATS=""

for u in "${USERS[@]}"; do
  USER_REPORT="$("${BASE_CMD[@]}" -u "$u" 2>/dev/null || true)"
  [[ -z "$USER_REPORT" ]] && USER_REPORT=""

  # Extract elapsed (seconds), GPUEff (%), GPUUtil (%) from WEIGHTED row
  metrics="$(
    awk '
      BEGIN {
        elapsed_secs = 0;
        gpu_eff      = 0;
        gpu_util     = 0;
      }

      # Convert time string to seconds. Supports:
      #   D-HH:MM:SS, HH:MM:SS (any digits in hours), MM:SS
      function timestr_to_secs(t,    days, hms, a, n, secs, hh, mm, ss) {
        secs = 0;
        if (t ~ /-/) {
          split(t, a, "-");
          days = a[1] + 0;
          hms  = a[2];
        } else {
          days = 0;
          hms  = t;
        }
        n = split(hms, a, ":");
        if (n == 3) {
          hh = a[1]+0; mm = a[2]+0; ss = a[3]+0;
        } else if (n == 2) {
          hh = 0; mm = a[1]+0; ss = a[2]+0;
        } else {
          return 0;
        }
        secs = ((days * 24 + hh) * 3600) + (mm * 60) + ss;
        return secs;
      }

      # WEIGHTED row: extract elapsed + GPUEff + GPUUtil by tokens
      /^[[:space:]]*WEIGHTED[[:space:]]/ {
        line = $0;

        # Split WEIGHTED line into tokens
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
        if (t_idx > 0)
          elapsed_secs = timestr_to_secs(a[t_idx]);

        # Collect all tokens after elapsed (kept in order, including ---)
        for (j in vals) delete vals[j];
        k = 0;
        for (i = t_idx + 1; i <= n; i++) {
          k++;
          vals[k] = a[i];
        }

        # After elapsed, WEIGHTED row layout is effectively:
        #   CPUEff, MemEff, GPUEff, GPUUtil, GPUMemEff, GPUMem
        # So GPUEff is vals[3], GPUUtil is vals[4], when present.
        gpueff_str  = "";
        gpuutil_str = "";

        if (k >= 3) gpueff_str  = vals[3];
        if (k >= 4) gpuutil_str = vals[4];

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
      }

      END {
        # Always print something, even if elapsed_secs == 0
        printf "%.0f %.4f %.4f\n", elapsed_secs, gpu_eff, gpu_util;
      }
    ' <<< "$USER_REPORT"
  )"

  # metrics is "secs gpueff gpuutil"
  read -r secs gpueff gpuutil <<< "$metrics"

  STATS+="$u $secs $gpueff $gpuutil"$'\n'
done

# --- 3) Aggregate per-user stats -> partition metrics -----------------------

printf '%s\n' "$STATS" | awk -v part="$PART" -v start="$START" -v end="$END" '
  BEGIN {
    OFS = "\t";
  }
  {
    # Skip completely blank lines (this avoids the extra empty "user" row)
    if (NF < 1) next;

    user   = $1;
    secs   = $2 + 0;
    ge     = $3 + 0;   # GPUEff %
    gu     = $4 + 0;   # GPUUtil %

    # Always keep the user, even if secs == 0
    user_secs[user]    = secs;
    user_gpueff[user]  = ge;
    user_gpuutil[user] = gu;
    seen[user] = 1;
  }
  END {
    printf "Partition: %s\n", part;
    printf "Start Date: %s\n", start;
    printf "End Date:   %s\n\n", (end=="" ? "now" : end);

    printf "%-15s %-12s %-16s\n",
    "User","GPU-hours","Time-weighted GPUEff (%)";
    printf "%-15s %-12s %-16s\n",
           "---------------","----------","----------------";

    PROCINFO["sorted_in"] = "@ind_str_asc";

    nusers              = 0;
    total_secs          = 0;
    total_gpuhours      = 0;
    sum_secs_gpueff     = 0;
    sum_gpuhours_gpueff = 0;

    for (u in seen) {
      nusers++;

      s  = user_secs[u];
      ge = user_gpueff[u];
      gu = user_gpuutil[u];

      total_secs      += s;
      sum_secs_gpueff += s * ge;

      hh = int(s / 3600);
      mm = int((s % 3600) / 60);
      ss = s % 60;
      elapsed_fmt = sprintf("%02d:%02d:%02d", hh, mm, ss);

      elapsed_hours = s / 3600.0;

      # Infer avg #GPUs from GPUUtil / GPUEff when both >0, else assume 1 GPU
      if (ge > 0 && gu > 0) {
        avg_gpus = gu / ge;
      } else {
        avg_gpus = 1.0;
      }

      gpu_hours = elapsed_hours * avg_gpus;

      total_gpuhours      += gpu_hours;
      sum_gpuhours_gpueff += gpu_hours * ge;

      printf "%-15s %-12.2f %-15.2f\n",
             u, gpu_hours, ge;
    }

    # summary
    printf "\nNo. of users: %d\n", nusers;
    printf "Total GPU-hours: %.2f\n", total_gpuhours;

    if (total_secs > 0) {
      timew_avg = sum_secs_gpueff / total_secs;
      printf "Partition time-weighted Avg GPUEff: %.4f%%\n", timew_avg;
    } else {
      printf "Partition time-weighted Avg GPUEff: n/a\n";
    }
  }
'
