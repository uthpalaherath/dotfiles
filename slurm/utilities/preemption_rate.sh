#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  preemption_rate.sh -r PARTITION -S START_DATE -E END_DATE

Example:
  ./preemption_rate.sh -r scavenger-gpu -S 2026-03-20 -E 2026-03-23

Notes:
- Dates are passed directly to sacct (-S / -E), e.g. YYYY-MM-DD or full timestamp.
- Pre-emption rate = PREEMPTED jobs / all returned jobs * 100.
EOF
}

partition=""
start=""
end=""

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

if [[ -z "$partition" || -z "$start" || -z "$end" ]]; then
  usage
  exit 1
fi

sacct --format=State%30 -X -a -S "$start" -E "$end" --partition="$partition" --noheader \
| awk -v partition="$partition" -v start="$start" -v end="$end" '
{
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
  if ($0 == "") next

  split(toupper($0), parts, /[[:space:]]+/)
  state = parts[1]

  total++
  counts[state]++
  if (state ~ /^PREEMPTED/) preempted++
}
END {
  if (total == 0) {
    printf "No jobs found for partition=%s between %s and %s\n", partition, start, end
    exit 2
  }

  rate = (preempted / total) * 100.0

  printf "Partition: %s\n", partition
  printf "Window:    %s to %s\n", start, end
  printf "Total jobs:      %d\n", total
  printf "PREEMPTED jobs:  %d\n", preempted
  printf "Pre-emption rate: %.2f%%\n", rate

  printf "\nState counts:\n"
  for (s in counts) {
    printf "  %-15s %d\n", s, counts[s]
  }
}'
