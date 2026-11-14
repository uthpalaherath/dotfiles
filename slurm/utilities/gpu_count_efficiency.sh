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
DEFAULT_GPU_MEM_MB="24576"

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
| awk -F'|' -v gpu_filter="$GPU_FILTER" -v default_gpu_mem_mb="$DEFAULT_GPU_MEM_MB" '
BEGIN {
  gpu_memory_mb["a100"] = 81920
  gpu_memory_mb["nvidia_a100-sxm4-80gb"] = 81920
  gpu_memory_mb["a40"] = 49152
  gpu_memory_mb["a5000"] = 24576
  gpu_memory_mb["a6000"] = 49152
  gpu_memory_mb["6000"] = 49152
  gpu_memory_mb["6000_ada"] = 49152
  gpu_memory_mb["rtx_6000_pro"] = 98304
  gpu_memory_mb["rtx_pro_6000"] = 98304
  gpu_memory_mb["6000_pro"] = 98304
  gpu_memory_mb["v100"] = 32768
  gpu_memory_mb["p100"] = 12288
  gpu_memory_mb["k80"] = 12288
  gpu_memory_mb["rtx8000"] = 49152
  gpu_memory_mb["rtx_2080"] = 11264
  gpu_memory_mb["2080rtx"] = 11264
  gpu_memory_mb["2080"] = 11264
  gpu_memory_mb["rtx_5000"] = 32768
  gpu_memory_mb["5000_ada"] = 32768
  gpu_memory_mb["titan_v"] = 12288
  gpu_memory_mb["h100"] = 81920
  gpu_memory_mb["h200"] = 143360
  gpu_memory_mb["h200_1g.18gb"] = 18432
  gpu_memory_mb["h200_3g.71gb"] = 72704
  gpu_memory_mb["h200_4g.71gb"] = 72704
  printf "%-24s %-14s %-18s %4s %11s %10s %12s %12s\n", "User", "JobID", "GPU Type", "GPUs", "Elapsed", "GPU Eff%", "GPU Mem (GB)", "GPU Mem Eff%"
  printf "%-24s %-14s %-18s %4s %11s %10s %12s %12s\n", "----", "-----", "--------", "----", "-------", "--------", "------------", "------------"
}

function gpu_model_mem_mb(model) {
  return (model in gpu_memory_mb) ? gpu_memory_mb[model] : default_gpu_mem_mb
}

function should_print_job(gpus) {
  return (gpu_filter == "") || (gpus == gpu_filter + 0)
}

function print_unmeasured_job() {
  if (current_gpus > 0 && should_print_job(current_gpus)) {
    printf "%-24s %-14s %-18s %4d %11s %10s %12s %12s\n", current_user, current_job, current_gpu_type, current_gpus, current_elapsed, "n/a", "n/a", "n/a"
  }
}

function print_current_job() {
  if (current_gpus <= 0 || !should_print_job(current_gpus)) {
    return
  }

  if (!current_measured || current_capacity_mb <= 0) {
    print_unmeasured_job()
    return
  }

  used_gpu_mem_gb = current_gpu_mem / 1000.0
  gpu_mem_eff = current_gpu_mem / current_capacity_mb * 100.0
  gpu_util_per_gpu = current_gpu_util / current_gpus
  printf "%-24s %-14s %-18s %4d %11s %9.2f%% %12.2f %11.2f%%\n", current_user, current_job, current_gpu_type, current_gpus, current_elapsed, gpu_util_per_gpu, used_gpu_mem_gb, gpu_mem_eff
}

function reset_current_job() {
  current_job = ""
  current_user = ""
  current_gpu_type = ""
  current_gpus = 0
  current_capacity_mb = 0
  current_elapsed = ""
  current_gpu_mem = 0
  current_gpu_util = 0
  current_measured = 0
}

function collect_step_usage(usage, parts, i, n, gpu_mem, gpu_util, found_usage) {
  gpu_mem = 0
  gpu_util = 0
  found_usage = 0
  n = split(usage, parts, ",")
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
    if (match(parts[i], /^gres\/gpumem=([0-9]+)M?$/, m)) {
      gpu_mem = m[1] + 0
      found_usage = 1
    }
    if (match(parts[i], /^gres\/gpuutil=([0-9]+)/, m)) {
      gpu_util = m[1] + 0
      found_usage = 1
    }
  }

  if (found_usage) {
    current_measured = 1
    if (gpu_mem > current_gpu_mem) {
      current_gpu_mem = gpu_mem
    }
    if (gpu_util > current_gpu_util) {
      current_gpu_util = gpu_util
    }
  }
}

{
  user = $1
  jobid = $2
  tres = $3
  usage = $4
  elapsed = $5

  # Check if this is a main job line (not .batch or .extern)
  if (jobid !~ /\./) {
    if (current_job != "") {
      print_current_job()
    }

    n = split(tres, parts, ",")
    model_gpu_count = 0
    model_gpu_capacity_mb = 0
    gpu_type = "unknown"
    generic_gpu_count = 0
    for (i = 1; i <= n; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
      if (match(parts[i], /^gres\/gpu:([^=]+)=([0-9]+)/, m)) {
        model = m[1]
        count = m[2] + 0
        model_gpu_count += count
        model_gpu_capacity_mb += count * gpu_model_mem_mb(model)
        gpu_type = (gpu_type == "unknown") ? model : gpu_type "," model
      } else if (match(parts[i], /^gres\/gpu=([0-9]+)/, m)) {
        generic_gpu_count += m[1] + 0
      }
    }
    if (model_gpu_count > 0) {
      gpu_count = model_gpu_count
      gpu_capacity_mb = model_gpu_capacity_mb
    } else {
      gpu_count = generic_gpu_count
      gpu_capacity_mb = generic_gpu_count * default_gpu_mem_mb
    }
    current_job = jobid
    current_user = user
    current_gpu_type = gpu_type
    current_gpus = gpu_count
    current_capacity_mb = gpu_capacity_mb
    current_elapsed = elapsed
    current_gpu_mem = 0
    current_gpu_util = 0
    current_measured = 0
  }
  # Collect telemetry from .batch and numbered job steps; .extern has no useful GPU work.
  else if (jobid !~ /\.extern$/ && current_job != "") {
    collect_step_usage(usage)
  }
}

END {
  if (current_job != "") {
    print_current_job()
  }
}'
