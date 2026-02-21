#!/usr/bin/env bash
#
# gpu_stats.sh
# Usage: gpu_stats.sh [-p PARTITION] [-s START_DATE] [-e END_DATE] [-h|--help]
#
# Produces three reports:
#  1) Job-counts per model-specific gres/gpu token (generic tokens removed)
#  2) Total GPUs per model-specific gres/gpu token (jobs × N)
#  3) Total GPUs requested per model (per-job aggregated, generic tokens ignored)
#
# Defaults:
PARTITION="h200alloc"
START_DATE="2025-10-01"
END_DATE="2025-10-08"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -r, --partition PART   Partition to query (default: ${PARTITION})
  -S, --start   DATE     sacct start date (inclusive) in YYYY-MM-DD (default: ${START_DATE})
  -E, --end     DATE     sacct end date (inclusive) in YYYY-MM-DD (default: ${END_DATE})
  -h, --help             Show this help and exit

Examples:
  gpu_stats.sh -p h200alloc -s 2025-10-01 -e 2025-10-08

Note: This version intentionally drops generic 'gres/gpu=N' tokens (UNSPECIFIED) from all reports.
EOF
}

# parse arguments
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

echo "=== GPU usage summary for partition: $PARTITION during window: $START_DATE - $END_DATE ==="
echo

# Base pipeline that emits one token per line (only model-specific tokens)
# NOTE: we explicitly exclude generic tokens 'gres/gpu=N' here.
base_pipeline() {
    sacct -S "$START_DATE" -E "$END_DATE" -n -P -a -X -r "$PARTITION" --format=JobID,AllocTRES%400 \
    | awk -F'|' '{ print $2 }' \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -Eo '^gres/gpu:[^=]+=[0-9]+'    # ONLY model-specific tokens (no plain gres/gpu=N)
}

# 1) Job-counts (model-specific only)
echo "---- 1) Job-count statistics -------------------------------------------"
base_pipeline \
| sort | uniq -c | sort -nr \
| awk '{
    cnt = ($1 + 0);
    token = $2;
    if (match(token,/^gres\/gpu:([^=]+)=([0-9]+)/, m)) {
      model = m[1];
      n = (m[2] + 0);
      printf("%6d jobs submitted requesting %d x %s\n", cnt, n, model);
    }
  }'

# 2) Total GPUs consumed per model-specific token (jobs * N)
echo
echo "---- 2) Total GPUs requested per model-specific gres/gpu token --------------------------------"
base_pipeline \
| sort | uniq -c \
| awk '{
    cnt=($1+0); token=$2;
    if (match(token,/^gres\/gpu:([^=]+)=([0-9]+)/,m)) {
      req=(m[2]+0); total=cnt*req;
      printf("%8d total GPUs  %s  (%d jobs × %d GPUs)\n",total,token,cnt,req);
    }
  }' | sort -nr

# 3) Aggregate totals per model (ignore generic tokens entirely)
echo
echo "---- 3) Total GPUs requested per model --------------------------"
sacct -S "$START_DATE" -E "$END_DATE" -n -P -a -X -r "$PARTITION" --format=JobID,AllocTRES%400 \
| awk -F'|' '
  $1 !~ /\./ {
    tres=$2;
    n = split(tres, parts, ",");
    delete per_model;
    # Only collect model-specific tokens; ignore generic tokens entirely
    for (i = 1; i <= n; i++) {
      p = parts[i];
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", p);
      if (match(p, /^gres\/gpu:([^=]+)=([0-9]+)/, ma)) {
        modelname = ma[1];
        cnt = (ma[2] + 0);
        per_model[modelname] += cnt;
      }
      # else: skip generic 'gres/gpu=N' tokens
    }
    # accumulate per-job model totals into global totals (only jobs that had model-specific tokens count)
    for (mname in per_model) {
      model_gpus[mname] += per_model[mname];
      model_jobs[mname] += 1;
    }
  }
  END {
    for (mname in model_gpus) {
      printf("%12d  GPUs  %s  (%d jobs)\n", model_gpus[mname], mname, model_jobs[mname]);
    }
  }' | sort -nr
