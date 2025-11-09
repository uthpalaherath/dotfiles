#!/usr/bin/env bash
#
# Time-weighted GPU efficiency calculator
# Usage: ./gpu_eff.sh [user] [partition] [startdate]
# Example: ./gpu_eff.sh ukh h200alloc 2025-10-01

set -euo pipefail

NETID="${1:-ukh}"
PARTITION="${2:-h200alloc}"
STARTDATE="${3:-$(date -d 'today' +%Y-%m-%d)}"

# Run slurm-report with plain output
REPORT=$(slurm-report -r "$PARTITION" --starttime "$STARTDATE" --user "$NETID" --plain)

# Parse and compute weighted average (sum(GPUEff)/sum(Elapsed_hours))
awk -v user="$NETID" -v part="$PARTITION" -v startdate="$STARTDATE" '
BEGIN {
  FS="[[:space:]]+"
  weighted_sum=0; sum_time=0
}
(/^User/ || /^[-]+$/ || /^Processing/ || NF < 8) { next }

{
  elapsed=$4
  gpueff=$8

  # skip missing GPUEff
  if (gpueff ~ /---/ || gpueff == "") next
  gsub("%","",gpueff)
  gsub(",","",gpueff)

  # parse elapsed to seconds (D-HH:MM:SS, HH:MM:SS, MM:SS)
  days=0
  n=split(elapsed, parts, "-")
  if (n==2) { days=parts[1]; elapsed=parts[2] } else { elapsed=parts[1] }

  split(elapsed, t, ":")
  if (length(t)==3)
    secs=t[1]*3600+t[2]*60+t[3]
  else if (length(t)==2)
    secs=t[1]*60+t[2]
  else
    secs=t[1]
  secs+=days*24*3600

  hours=secs/3600.0

  if (hours>0 && gpueff ~ /^[0-9.]+$/) {
    weighted_sum += (gpueff * hours)
    sum_time += hours
  }
}
END {
  if (sum_time>0) {
    weighted = weighted_sum / sum_time
    printf "Time-weighted GPU Efficiency Average for user %s on partition %s since %s = %.4f%%\n", user, part, startdate, weighted
  } else {
    printf "No valid GPU efficiency data found for user %s on partition %s since %s.\n", user, part, startdate
  }
}
' <<< "$REPORT"
