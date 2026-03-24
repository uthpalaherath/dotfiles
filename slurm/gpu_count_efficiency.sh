#!/usr/bin/env bash
#
# gpu_job_efficiency.sh
# Usage: gpu_job_efficiency.sh [-r PARTITION] [-S START_DATE] [-E END_DATE] [-g GPUS] [-h|--help]
#
# Reports user, job ID, GPUs allocated, GPU memory usage, and GPU efficiency per job
#
# Defaults:
PARTITION="h200alloc"
START_DATE="2025-10-01"
END_DATE="2025-10-08"
GPU_FILTER=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -r, --partition PART   Partition to query (default: ${PARTITION})
  -S, --start   DATE     sacct start date (inclusive) in YYYY-MM-DD (default: ${START_DATE})
  -E, --end     DATE     sacct end date (inclusive) in YYYY-MM-DD (default: ${END_DATE})
  -g, --gpus    N        Filter jobs with exactly N GPUs allocated (optional)
  -h, --help             Show this help and exit

Examples:
  $(basename "$0") -r scavenger-h200 -S 2026-03-17 -E 2026-03-24
  $(basename "$0") -r scavenger-h200 -S 2026-03-17 -E 2026-03-24 -g 8
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--partition)
      PARTITION="$2"; shift 2;;
    -S|--start)
      START_DATE="$2"; shift 2;;
    -E|--end)
      END_DATE="$2"; shift 2;;
    -g|--gpus)
      GPU_FILTER="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 2;;
  esac
done

set -euo pipefail

echo
if [[ -n "$GPU_FILTER" ]]; then
  echo "Finding jobs requesting $GPU_FILTER GPUs..."
fi
echo

sacct -P --format=user,JobID,AllocTRES,TresUsageInTot,Elapsed -S "$START_DATE" -E "$END_DATE" --partition="$PARTITION" -a --noheader \
| awk -F'|' -v gpu_filter="$GPU_FILTER" '
BEGIN {
  printf "%-10s %-14s %4s %11s %12s %10s\n", "User", "JobID", "GPUs", "Elapsed", "GPU Mem (GB)", "GPU Eff%"
  printf "%-10s %-14s %4s %11s %12s %10s\n", "----", "-----", "----", "-------", "------------", "--------"
}
{
  user = $1
  jobid = $2
  tres = $3
  usage = $4
  elapsed = $5

  # Check if this is a main job line (not .batch or .extern)
  if (jobid !~ /\./) {
    # Parse AllocTRES for GPU count (gres/gpu:model=N)
    n = split(tres, parts, ",")
    gpu_count = 0
    for (i = 1; i <= n; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
      if (match(parts[i], /^gres\/gpu:[^=]+=([0-9]+)/, m)) {
        gpu_count += m[1]
      }
    }
    current_job = jobid
    current_user = user
    current_gpus = gpu_count
    current_elapsed = elapsed
  }
  # Check if this is a .batch line
  else if (jobid ~ /\.batch$/ && current_job != "") {
    # Parse TresUsageInTot for GPU memory and utilization
    gpu_mem = 0
    gpu_util = 0
    n = split(usage, parts, ",")
    for (i = 1; i <= n; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
      if (match(parts[i], /^gres\/gpumem=([0-9]+)M?$/, m)) {
        gpu_mem = m[1] + 0
      }
      if (match(parts[i], /^gres\/gpuutil=([0-9]+)/, m)) {
        gpu_util = m[1] + 0
      }
    }

    # Apply GPU filter if specified
    if ((gpu_filter == "") || (current_gpus == gpu_filter+0)) {
      if (current_gpus > 0) {
        gpu_mem_gb = gpu_mem / 1000.0
        gpu_util_per_gpu = gpu_util / current_gpus
        printf "%-10s %-14s %4d %11s %12.2f %9.2f%%\n", current_user, current_job, current_gpus, current_elapsed, gpu_mem_gb, gpu_util_per_gpu
      }
    }

    # Reset for next job
    current_job = ""
    current_user = ""
    current_gpus = 0
    current_elapsed = ""
  }
}'
