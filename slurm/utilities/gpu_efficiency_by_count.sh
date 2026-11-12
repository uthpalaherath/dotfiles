#!/usr/bin/env bash
#
# gpu_efficiency_by_count.sh
# Usage: gpu_efficiency_by_count.sh [-r PARTITION] [-S START_DATE] [-E END_DATE] [-u] [-a] [-n N] [-h|--help]
#
# Groups jobs by requested GPU count and reports request counts plus
# time-weighted averages of GPU utilization efficiency and GPU memory efficiency
# for jobs with Slurm GPU telemetry in their .batch step.
#
# With -u/-a, additionally breaks each GPU-count bucket down by user and/or
# account so you can see who requested 6 GPUs, 8 GPUs, etc.
#

PARTITION="h200alloc"
START_DATE="2025-10-01"
END_DATE="2025-10-08"
DEFAULT_GPU_MEM_MB="24576"
BY_USER=0
BY_ACCOUNT=0
TOP_N=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -r, --partition PART      Partition to query (default: ${PARTITION})
  -S, --start DATE          sacct start date (inclusive) in YYYY-MM-DD (default: ${START_DATE})
  -E, --end DATE            sacct end date (inclusive) in YYYY-MM-DD (default: ${END_DATE})
  -u, --by-user             Also break each GPU-count bucket down by user
  -a, --by-account          Also break each GPU-count bucket down by account
  -n, --top N               Limit breakdown to the top N rows per bucket (default: all)
  -h, --help                Show this help and exit

Examples:
  $(basename "$0") -r gpu -S 2026-05-01 -E 2026-05-31
  $(basename "$0") -r h200-hp -S 2026-07-01 -E 2026-07-31 -u
  $(basename "$0") -r h200-hp -S 2026-07-01 -E 2026-07-31 -u -a -n 10
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
    -u|--by-user)
      BY_USER=1; shift;;
    -a|--by-account)
      BY_ACCOUNT=1; shift;;
    -n|--top)
      TOP_N="$2"; shift 2;;
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
echo "=== GPU efficiency by count for partition: $PARTITION during window: $START_DATE - $END_DATE ==="
echo

sacct -P --format=user,account,JobID,AllocTRES,TresUsageInTot,Elapsed -S "$START_DATE" -E "$END_DATE" --partition="$PARTITION" -a --noheader \
| awk -F'|' -v default_gpu_mem_mb="$DEFAULT_GPU_MEM_MB" -v by_user="$BY_USER" -v by_account="$BY_ACCOUNT" -v top_n="$TOP_N" '
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

function record_job(gpu_type, gpus, capacity_mb, elapsed, gpu_mem_mb, gpu_util, key, seconds, gpu_eff, mem_eff, ekey) {
  if (gpus <= 0 || capacity_mb <= 0) {
    return
  }

  seconds = elapsed_to_seconds(elapsed)
  if (seconds <= 0) {
    return
  }

  gpu_eff = gpu_util / gpus
  mem_eff = gpu_mem_mb / capacity_mb * 100.0

  key = gpu_type SUBSEP gpus
  eff_jobs[key] += 1
  total_seconds[key] += seconds
  weighted_gpu_eff[key] += gpu_eff * seconds
  weighted_mem_eff[key] += mem_eff * seconds

  if (by_user) {
    ekey = key SUBSEP "user" SUBSEP current_user
    e_eff_jobs[ekey] += 1
    e_seconds[ekey] += seconds
    e_gpu_eff[ekey] += gpu_eff * seconds
    e_mem_eff[ekey] += mem_eff * seconds
  }
  if (by_account) {
    ekey = key SUBSEP "account" SUBSEP current_account
    e_eff_jobs[ekey] += 1
    e_seconds[ekey] += seconds
    e_gpu_eff[ekey] += gpu_eff * seconds
    e_mem_eff[ekey] += mem_eff * seconds
  }
}

function record_entity(key, tag, name, ekey) {
  if (name == "") {
    name = "unknown"
  }
  ekey = key SUBSEP tag SUBSEP name
  e_jobs[ekey] += 1
  e_gpus[ekey] += (key_gpus_of[key] + 0)
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

  key_gpus_of[key] = gpus
  if (by_user) {
    record_entity(key, "user", current_user)
  }
  if (by_account) {
    record_entity(key, "account", current_account)
  }
}

function collect_step_usage(usage, parts, i, n, gpu_mem_mb, gpu_util, found_usage) {
  gpu_mem_mb = 0
  gpu_util = 0
  found_usage = 0
  n = split(usage, parts, ",")
  for (i = 1; i <= n; i++) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
    if (match(parts[i], /^gres\/gpumem=([0-9]+)M?$/, m)) {
      gpu_mem_mb = m[1] + 0
      found_usage = 1
    }
    if (match(parts[i], /^gres\/gpuutil=([0-9]+)/, m)) {
      gpu_util = m[1] + 0
      found_usage = 1
    }
  }

  if (found_usage) {
    current_measured = 1
    if (gpu_mem_mb > current_gpu_mem) {
      current_gpu_mem = gpu_mem_mb
    }
    if (gpu_util > current_gpu_util) {
      current_gpu_util = gpu_util
    }
  }
}

function flush_current_job() {
  if (current_job != "" && current_measured) {
    record_job(current_gpu_type, current_gpus, current_capacity_mb, current_elapsed, current_gpu_mem, current_gpu_util)
  }
}

# Sort the names in list[] (1..count) by jobs descending, then name ascending.
function sort_entities(list, counts, count, i, j, tmp) {
  for (i = 2; i <= count; i++) {
    for (j = i; j > 1; j--) {
      if (counts[list[j]] > counts[list[j-1]] ||
          (counts[list[j]] == counts[list[j-1]] && list[j] < list[j-1])) {
        tmp = list[j]; list[j] = list[j-1]; list[j-1] = tmp
      } else {
        break
      }
    }
  }
}

function print_breakdown(tag, label,   gpus, key, key_parts, gpu_type, key_gpus, ekey, ekey_parts,
                         names, count, i, shown, ekey_i, avg_gpu, avg_mem, w, dashes, fmt, fmt_na) {
  w = 0
  for (ekey in e_jobs) {
    split(ekey, ekey_parts, SUBSEP)
    if (ekey_parts[3] == tag && length(ekey_parts[4]) > w) {
      w = length(ekey_parts[4])
    }
  }
  if (w < 8) {
    w = 8
  }
  dashes = sprintf("%*s", w, "")
  gsub(/ /, "-", dashes)
  fmt = "%-10s %4d %-" w "s %10d %13d %10d %11.2f%% %15.2f%%\n"
  fmt_na = "%-10s %4d %-" w "s %10d %13d %10d %12s %15s\n"

  printf "\n=== Breakdown by %s ===\n\n", label
  printf "%-10s %4s %-" w "s %10s %13s %10s %12s %15s\n", "GPU Type", "GPUs", (tag == "user" ? "User" : "Account"), "Total Jobs", "Measured Jobs", "Total GPUs", "TWA GPU Eff%", "TWA GPU Mem Eff%"
  printf "%-10s %4s %-" w "s %10s %13s %10s %12s %15s\n", "--------", "----", dashes, "----------", "-------------", "----------", "------------", "----------------"

  for (gpus = min_gpus; gpus <= max_gpus; gpus++) {
    for (key in jobs) {
      split(key, key_parts, SUBSEP)
      gpu_type = key_parts[1]
      key_gpus = key_parts[2] + 0
      if (key_gpus != gpus) {
        continue
      }

      count = 0
      delete names
      delete name_jobs
      for (ekey in e_jobs) {
        split(ekey, ekey_parts, SUBSEP)
        if (ekey_parts[1] != gpu_type || (ekey_parts[2] + 0) != key_gpus || ekey_parts[3] != tag) {
          continue
        }
        names[++count] = ekey_parts[4]
        name_jobs[ekey_parts[4]] = e_jobs[ekey]
      }
      if (count == 0) {
        continue
      }
      sort_entities(names, name_jobs, count)

      shown = 0
      for (i = 1; i <= count; i++) {
        if (top_n > 0 && shown >= top_n) {
          printf "%-10s %4d %s\n", "", gpus, "... " (count - shown) " more"
          break
        }
        ekey_i = gpu_type SUBSEP key_gpus SUBSEP tag SUBSEP names[i]
        if (e_seconds[ekey_i] > 0) {
          avg_gpu = e_gpu_eff[ekey_i] / e_seconds[ekey_i]
          avg_mem = e_mem_eff[ekey_i] / e_seconds[ekey_i]
          printf fmt, gpu_type, gpus, names[i], e_jobs[ekey_i], e_eff_jobs[ekey_i], e_gpus[ekey_i], avg_gpu, avg_mem
        } else {
          printf fmt_na, gpu_type, gpus, names[i], e_jobs[ekey_i], 0, e_gpus[ekey_i], "n/a", "n/a"
        }
        shown++
      }
    }
  }
}

{
  user = $1
  account = $2
  jobid = $3
  tres = $4
  usage = $5
  elapsed = $6

  if (jobid !~ /\./) {
    flush_current_job()

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
    current_user = (user == "") ? "unknown" : user
    current_account = (account == "") ? "unknown" : account
    current_gpu_type = gpu_type
    current_gpus = gpu_count
    current_capacity_mb = gpu_capacity_mb
    current_elapsed = elapsed
    current_gpu_mem = 0
    current_gpu_util = 0
    current_measured = 0
    record_request(gpu_type, gpu_count)
  } else if (jobid !~ /\.extern$/ && current_job != "") {
    collect_step_usage(usage)
  }
}

END {
  flush_current_job()

  printf "%-10s %4s %10s %13s %10s %12s %15s\n", "GPU Type", "GPUs", "Total Jobs", "Measured Jobs", "Total GPUs", "TWA GPU Eff%", "TWA GPU Mem Eff%"
  printf "%-10s %4s %10s %13s %10s %12s %15s\n", "--------", "----", "----------", "-------------", "----------", "------------", "----------------"
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
        printf "%-10s %4d %10d %13d %10d %11.2f%% %15.2f%%\n", gpu_type, gpus, jobs[key], eff_jobs[key], total_gpus[key], gpu_avg, mem_avg
      } else {
        printf "%-10s %4d %10d %13d %10d %12s %15s\n", gpu_type, gpus, jobs[key], 0, total_gpus[key], "n/a", "n/a"
      }
    }
  }

  if (by_user) {
    print_breakdown("user", "user")
  }
  if (by_account) {
    print_breakdown("account", "account")
  }
}'
