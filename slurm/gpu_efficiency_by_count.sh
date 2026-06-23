#!/usr/bin/env bash
#
# gpu_efficiency_by_count.sh
# Usage: gpu_efficiency_by_count.sh [-r PARTITION] [-S START_DATE] [-E END_DATE] [-h|--help]
#
# Groups jobs by requested GPU count and reports request counts plus
# time-weighted averages of GPU utilization efficiency and GPU memory efficiency
# for jobs with Slurm GPU telemetry in their .batch step.
#

PARTITION="h200alloc"
START_DATE="2025-10-01"
END_DATE="2025-10-08"
DEFAULT_GPU_MEM_MB="24576"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -r, --partition PART      Partition to query (default: ${PARTITION})
  -S, --start DATE          sacct start date (inclusive) in YYYY-MM-DD (default: ${START_DATE})
  -E, --end DATE            sacct end date (inclusive) in YYYY-MM-DD (default: ${END_DATE})
  -h, --help                Show this help and exit

Examples:
  $(basename "$0") -r gpu -S 2026-05-01 -E 2026-05-31
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
echo "=== GPU efficiency by requested GPU count for partition: $PARTITION during window: $START_DATE - $END_DATE ==="
echo "Using model-specific GPU memory sizes when available."
echo

sacct -P --format=user,JobID,AllocTRES,TresUsageInTot,Elapsed -S "$START_DATE" -E "$END_DATE" --partition="$PARTITION" -a --noheader \
| awk -F'|' -v default_gpu_mem_mb="$DEFAULT_GPU_MEM_MB" '
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
}

function elapsed_to_seconds(elapsed, parts, tparts, tcount, days, h, m, s) {
  days = 0
  if (elapsed ~ /-/) {
    split(elapsed, parts, "-")
    days = parts[1] + 0
    elapsed = parts[2]
  }

  tcount = split(elapsed, tparts, ":")
  if (tcount == 3) {
    h = tparts[1] + 0
    m = tparts[2] + 0
    s = tparts[3] + 0
  } else if (tcount == 2) {
    h = 0
    m = tparts[1] + 0
    s = tparts[2] + 0
  } else {
    h = 0
    m = 0
    s = elapsed + 0
  }

  return (days * 86400) + (h * 3600) + (m * 60) + s
}

function gpu_model_mem_mb(model) {
  return (model in gpu_memory_mb) ? gpu_memory_mb[model] : default_gpu_mem_mb
}

function record_job(gpu_type, gpus, capacity_mb, elapsed, usage, parts, i, n, key, gpu_mem_mb, gpu_util, seconds, gpu_eff, mem_eff) {
  if (gpus <= 0 || capacity_mb <= 0) {
    return
  }

  seconds = elapsed_to_seconds(elapsed)
  if (seconds <= 0) {
    return
  }

  gpu_mem_mb = 0
  gpu_util = 0
  n = split(usage, parts, ",")
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
    if (match(parts[i], /^gres\/gpumem=([0-9]+)M?$/, m)) {
      gpu_mem_mb = m[1] + 0
    }
    if (match(parts[i], /^gres\/gpuutil=([0-9]+)/, m)) {
      gpu_util = m[1] + 0
    }
  }

  gpu_eff = gpu_util / gpus
  mem_eff = gpu_mem_mb / capacity_mb * 100.0

  key = gpu_type SUBSEP gpus
  eff_jobs[key] += 1
  total_seconds[key] += seconds
  weighted_gpu_eff[key] += gpu_eff * seconds
  weighted_mem_eff[key] += mem_eff * seconds
}

function record_request(gpu_type, gpus, key) {
  if (gpus <= 0) {
    return
  }

  key = gpu_type SUBSEP gpus
  jobs[key] += 1
  total_gpus[key] += gpus
  if ((min_gpus == "") || (gpus < min_gpus)) {
    min_gpus = gpus
  }
  if (gpus > max_gpus) {
    max_gpus = gpus
  }
}

{
  jobid = $2
  tres = $3
  usage = $4
  elapsed = $5

  if (jobid !~ /\./) {
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
    current_gpu_type = gpu_type
    current_gpus = gpu_count
    current_capacity_mb = gpu_capacity_mb
    current_elapsed = elapsed
    record_request(gpu_type, gpu_count)
  } else if (jobid ~ /\.batch$/ && current_job != "") {
    record_job(current_gpu_type, current_gpus, current_capacity_mb, current_elapsed, usage)
    current_job = ""
    current_gpu_type = ""
    current_gpus = 0
    current_capacity_mb = 0
    current_elapsed = ""
  }
}

END {
  printf "%-10s %4s %10s %13s %20s %12s %15s\n", "GPU Type", "GPUs", "Total Jobs", "Measured Jobs", "Total Requested GPUs", "TWA GPU Eff%", "TWA GPU Mem Eff%"
  printf "%-10s %4s %10s %13s %20s %12s %15s\n", "--------", "----", "----------", "-------------", "--------------------", "-----------", "---------------"
  for (gpus = min_gpus; gpus <= max_gpus; gpus++) {
    for (key in jobs) {
      split(key, key_parts, SUBSEP)
      gpu_type = key_parts[1]
      key_gpus = key_parts[2] + 0
      if (key_gpus != gpus) {
        continue
      }
      if (total_seconds[key] > 0) {
        gpu_avg = weighted_gpu_eff[key] / total_seconds[key]
        mem_avg = weighted_mem_eff[key] / total_seconds[key]
        printf "%-10s %4d %10d %13d %20d %11.2f%% %14.2f%%\n", gpu_type, gpus, jobs[key], eff_jobs[key], total_gpus[key], gpu_avg, mem_avg
      } else {
        printf "%-10s %4d %10d %13d %20d %12s %15s\n", gpu_type, gpus, jobs[key], 0, total_gpus[key], "n/a", "n/a"
      }
    }
  }
}'
