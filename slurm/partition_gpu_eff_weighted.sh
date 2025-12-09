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
#   3) Combine users into:
#         - elapsed-time-weighted Avg GPUEff
#         - GPU-hour-weighted Avg GPUEff (using inferred GPU-hours)
#
# Usage: ./partition_gpu_eff_weighted.sh -p PARTITION -s STARTDATE -e ENDDATE

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
      echo "Example: $0 -p h200alloc -s 2025-12-01 -e 2025-12-05"
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

# --- 2) For each user, get WEIGHTED row from `slurm-report --plain -u user` --

BASE_CMD=(slurm-report -r "$PART" -S "$START" --plain)
if [[ -n "$END" ]]; then
  BASE_CMD+=(-E "$END")
fi

STATS=""

for u in "${USERS[@]}"; do
  USER_REPORT="$("${BASE_CMD[@]}" -u "$u" 2>/dev/null || true)"
  [[ -z "$USER_REPORT" ]] && continue

  # Extract elapsed (seconds), GPUEff (%), GPUUtil (%) from WEIGHTED row
  metrics="$(
    awk '
      BEGIN {
        FS = " ";
        elapsed_secs  = 0;
        gpu_eff       = 0;
        gpu_util      = 0;
        gpueff_start  = 0;
        gpuutil_start = 0;
        gpumemeff_start = 0;
      }

      # Convert time string to seconds. Supports:
      #   D-HH:MM:SS, HH:MM:SS, MM:SS
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

      # Header line: capture character positions of GPUEff, GPUUtil, GPUMemEff
      /^User[[:space:]]+JobID/ {
        header = $0;
        if (match(header, /GPUEff/))    gpueff_start    = RSTART;
        if (match(header, /GPUUtil/))   gpuutil_start   = RSTART;
        if (match(header, /GPUMemEff/)) gpumemeff_start = RSTART;
        next;
      }

      # WEIGHTED row: extract elapsed + GPUEff + GPUUtil
      /WEIGHTED/ {
        line = $0;

        # Find elapsed time as the first time-like token on this line
        n = split(line, a, /[[:space:]]+/);
        t_idx = 0;
        for (i = 1; i <= n; i++) {
          if (a[i] ~ /^[0-9]+-[0-9]{1,2}:[0-9]{2}:[0-9]{2}$/ ||
              a[i] ~ /^[0-9]{1,2}:[0-9]{2}:[0-9]{2}$/ ||
              a[i] ~ /^[0-9]{1,2}:[0-9]{2}$/) {
            t_idx = i;
            break;
          }
        }
        if (t_idx > 0)
          elapsed_secs = timestr_to_secs(a[t_idx]);

        # GPUEff column substring
        col = "";
        if (gpueff_start > 0 && gpuutil_start > gpueff_start) {
          col = substr(line, gpueff_start, gpuutil_start - gpueff_start);
        } else if (gpueff_start > 0) {
          col = substr(line, gpueff_start);
        }
        if (col != "" && match(col, /[0-9]+(\.[0-9]+)?%/)) {
          gstr = substr(col, RSTART, RLENGTH);
          gsub(/%/, "", gstr);
          gpu_eff = gstr + 0;
        } else {
          gpu_eff = 0;
        }

        # GPUUtil column substring
        colu = "";
        if (gpuutil_start > 0 && gpumemeff_start > gpuutil_start) {
          colu = substr(line, gpuutil_start, gpumemeff_start - gpuutil_start);
        } else if (gpuutil_start > 0) {
          colu = substr(line, gpuutil_start);
        }
        if (colu != "" && match(colu, /[0-9]+(\.[0-9]+)?%/)) {
          ustr = substr(colu, RSTART, RLENGTH);
          gsub(/%/, "", ustr);
          gpu_util = ustr + 0;
        } else {
          gpu_util = 0;
        }
      }

      END {
        if (elapsed_secs > 0) {
          # print: elapsed_seconds gpueff gpuutil
          printf "%.0f %.4f %.4f\n", elapsed_secs, gpu_eff, gpu_util;
        }
      }
    ' <<< "$USER_REPORT"
  )"

  [[ -z "$metrics" ]] && continue

  # metrics is "secs gpueff gpuutil"
  read -r secs gpueff gpuutil <<< "$metrics"

  STATS+="$u $secs $gpueff $gpuutil"$'\n'
done

if [[ -z "$STATS" ]]; then
  echo "No per-user WEIGHTED rows with non-zero elapsed found for partition=$PART between $START and ${END:-now}"
  exit 0
fi

# --- 3) Aggregate per-user stats -> partition metrics -----------------------

printf '%s\n' "$STATS" | awk -v part="$PART" -v start="$START" -v end="$END" '
  BEGIN {
    OFS = "\t";
  }
  {
    user   = $1;
    secs   = $2 + 0;
    gpueff = $3 + 0;   # %
    gpuutil= $4 + 0;   # %

    if (secs <= 0) next;

    # Store per-user basics
    user_secs[user]    = secs;
    user_gpueff[user]  = gpueff;
    user_gpuutil[user] = gpuutil;
    seen[user] = 1;

    total_secs      += secs;
    sum_secs_gpueff += secs * gpueff;   # for elapsed-time-weighted avg
  }
  END {
    printf "Partition: %s\n", part;
    printf "Start Date: %s\n", start;
    printf "End Date:   %s\n\n", (end=="" ? "now" : end);

    printf "%-15s %-12s %-12s %-8s %-16s\n",
           "User","Elapsed","GPU-hours","GPUs","Time-wtd GPUEff";
    printf "%-15s %-12s %-12s %-8s %-16s\n",
           "---------------","----------","----------","----","----------------";

    PROCINFO["sorted_in"] = "@ind_str_asc";

    total_gpuhours        = 0;
    sum_gpuhours_gpueff   = 0;
    nusers                = 0;

    for (u in seen) {
      nusers++;
      s   = user_secs[u];
      ge  = user_gpueff[u];
      gu  = user_gpuutil[u];

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

      printf "%-15s %-12s %-12.2f %-8.2f %-15.4f%%\n",
             u, elapsed_fmt, gpu_hours, avg_gpus, ge;
    }

    # --- summary section additions ---
    # total users and total elapsed time
    printf "\nNo. of users: %d\n", nusers;
    if (total_secs > 0) {
      tot_hh = int(total_secs / 3600);
      tot_mm = int((total_secs % 3600) / 60);
      tot_ss = total_secs % 60;
      printf "Total elapsed time: %02d:%02d:%02d (%.2f hours)\n",
             tot_hh, tot_mm, tot_ss, total_secs / 3600.0;
    } else {
      printf "Total elapsed time: 00:00:00 (0.00 hours)\n";
    }

    printf "Total GPU hours: %.2f\n", total_gpuhours;

    if (total_secs > 0) {
      timew_avg = sum_secs_gpueff / total_secs;
      printf "Partition time-weighted Avg GPUEff: %.4f%%\n", timew_avg;
    } else {
      printf "Partition time-weighted Avg GPUEff: n/a\n";
    }

    if (total_gpuhours > 0) {
      gpuhr_avg = sum_gpuhours_gpueff / total_gpuhours;
      printf "Partition GPU-hour-weighted Avg GPUEff: %.4f%%\n", gpuhr_avg;
    } else {
      printf "Partition GPU-hour-weighted Avg GPUEff: n/a\n";
    }
  }
'
