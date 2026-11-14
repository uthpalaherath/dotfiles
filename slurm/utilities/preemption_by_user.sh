#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF2'
Usage:
  preemption_by_user.sh -S START_DATE [-E END_DATE] [-r PARTITION]

Example:
  ./preemption_by_user.sh -S 2026-03-20 -E 2026-03-23 -r scavenger-gpu
  ./preemption_by_user.sh -S 2026-03-20    # through now

Notes:
- Dates are passed directly to sacct (-S / -E), e.g. YYYY-MM-DD or full timestamp.
- END_DATE defaults to now.
- Uses sacct -D so every requeued run of a job is counted, not just the last one.
- PREEMPTIONS = number of pre-empted runs; JOBS = distinct job IDs affected.
EOF2
}

partition=""
start=""
end="now"

while getopts ":r:S:E:h" opt; do
  case "$opt" in
    r) partition="$OPTARG" ;;
    S) start="$OPTARG" ;;
    E) end="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$start" ]]; then
  usage
  exit 1
fi

sacct_args=(-a -X -D -n -P -s PR -S "$start" -E "$end" --format=User,JobID)
[[ -n "$partition" ]] && sacct_args+=(--partition="$partition")

sacct "${sacct_args[@]}" \
| awk -F'|' '
NF >= 2 && $1 != "" {
  n[$1]++
  if (!seen[$1 SUBSEP $2]++) { jobs[$1]++; njobs++ }
  total++
}
END {
  if (total == 0) { print "No pre-empted jobs found." > "/dev/stderr"; exit 2 }
  printf "%-16s %12s %8s\n", "USER", "PREEMPTIONS", "JOBS"
  for (u in n) printf "%-16s %12d %8d\n", u, n[u], jobs[u] | "sort -k2,2nr"
  close("sort -k2,2nr")
  printf "%-16s %12d %8d\n", "TOTAL", total, njobs
}'
