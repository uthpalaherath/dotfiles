#!/usr/bin/env bash
# partition_gpu_eff_summary.sh
# Compute GPU-hour-weighted Avg GPUEff with summary info
# Usage: ./partition_gpu_eff_summary.sh -p PARTITION -s STARTDATE -e ENDDATE

set -euo pipefail

PART="h200alloc"
START="$(date -d 'today' +%Y-%m-%d)"
END=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--partition) PART="$2"; shift 2;;
    -s|--start) START="$2"; shift 2;;
    -e|--end)   END="$2";   shift 2;;
    -h|--help)
      echo "Usage: $0 [-p PARTITION] [-s STARTDATE] [-e ENDDATE]"
      echo "Example: $0 -p h200alloc -s 2025-10-01 -e 2025-10-31"
      exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

# Build slurm-report command
CMD=(slurm-report -r "$PART" -S "$START" --summary --plain)
if [[ -n "$END" ]]; then
  CMD+=(-E "$END")
fi

REPORT="$("${CMD[@]}" 2>/dev/null || true)"

# If slurm-report returned nothing, exit
if [[ -z "$REPORT" ]]; then
  echo "No summary output for partition=$PART between $START and ${END:-now}"
  exit 0
fi

# If the report says "No valid jobs found", stop
if printf '%s\n' "$REPORT" | grep -qi "No valid jobs found"; then
  echo "No valid jobs found for partition=$PART between $START and ${END:-now}"
  exit 0
fi

awk -v part="$PART" -v start="$START" -v end="$END" '
  BEGIN {
    FS="[[:space:]]+";
    sum_weighted = 0;
    sum_hours = 0;
    users = 0;
    in_table = 0;
  }
  /^[-]{2,}$/ { in_table=1; next }
  !in_table { next }

  {
    user = $1;
    gpu_hours_raw = $3;
    avg_eff_raw = $8;

    # clean GPU Hours
    gsub(/,/, "", gpu_hours_raw);
    if (gpu_hours_raw ~ /^[0-9]+(\.[0-9]+)?$/)
      gpu_hours = gpu_hours_raw + 0;
    else
      gpu_hours = 0;

    # clean Avg GPU Eff
    if (avg_eff_raw == "---" || avg_eff_raw == "") {
      avg_eff = 0;
    } else {
      gsub("%", "", avg_eff_raw);
      gsub(/,/, "", avg_eff_raw);
      if (avg_eff_raw ~ /^[0-9]+(\.[0-9]+)?$/)
        avg_eff = avg_eff_raw + 0;
      else
        avg_eff = 0;
    }

    if (gpu_hours > 0) {
      sum_weighted += avg_eff * gpu_hours;
      sum_hours += gpu_hours;
    }
    users++;
  }
  END {
    if (sum_hours > 0) {
      weighted = sum_weighted / sum_hours;
      printf "Partition: %s\n", part;
      printf "Start Date: %s\n", start;
      printf "End Date:   %s\n", (end=="" ? "now" : end);
      printf "Users counted: %d\n", users;
      printf "Total GPU hours: %.2f\n", sum_hours;
      printf "GPU-hour-weighted Avg GPUEff: %.4f%%\n", weighted;
    } else {
      print "No GPU hours found in slurm-report summary output.";
    }
  }
' <<< "$REPORT"
