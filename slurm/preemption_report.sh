#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF2'
Usage:
  preemption_report.sh -S START_DATE [-E END_DATE] [-r PARTITION] [-o OUTDIR]

Example:
  ./preemption_report.sh -S 2026-07-01 -r scavenger-gpu

Writes to OUTDIR (default: ./preemptions_START_END):
  preemptions_raw.csv      one row per preemption: user,jobid,partition,start,preempted_at
  preemptions_by_job.csv   user,jobid,partition,preemptions
  preemptions_YYYY-MM.csv  one per month: user, one column per day, total

Notes:
- END_DATE defaults to now.
- Uses sacct -D so every requeued run of a job is counted, not just the last one.
- A preemption is bucketed by its End time (when the run was pre-empted).
EOF2
}

partition=""
start=""
end="now"
outdir=""

while getopts ":r:S:E:o:h" opt; do
  case "$opt" in
    r) partition="$OPTARG" ;;
    S) start="$OPTARG" ;;
    E) end="$OPTARG" ;;
    o) outdir="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$start" ]]; then
  usage
  exit 1
fi

# Normalize the window so End times can be compared as strings
start_ts=$(date -d "$start" +%Y-%m-%dT%H:%M:%S)
end_ts=$(date -d "$end" +%Y-%m-%dT%H:%M:%S)

outdir="${outdir:-./preemptions_${start_ts%%T*}_${end_ts%%T*}}"
mkdir -p "$outdir"
raw="$outdir/preemptions_raw.csv"

sacct_args=(-a -X -D -n -P -s PR -S "$start_ts" -E "$end_ts"
            --format=User,JobID,Partition,Start,End)
[[ -n "$partition" ]] && sacct_args+=(--partition="$partition")

echo "user,jobid,partition,start,preempted_at" > "$raw"
sacct "${sacct_args[@]}" \
| awk -F'|' -v OFS=',' -v s="$start_ts" -v e="$end_ts" '
  $1 != "" && $5 ~ /^[0-9]{4}-/ && $5 >= s && $5 < e { print $1, $2, $3, $4, $5 }
' | sort -t, -k5,5 >> "$raw"

n=$(( $(wc -l < "$raw") - 1 ))
if (( n == 0 )); then
  echo "No pre-empted jobs found." >&2
  exit 2
fi

# Per user/job counts
{
  echo "user,jobid,partition,preemptions"
  tail -n +2 "$raw" | awk -F, -v OFS=',' '{ c[$1 OFS $2 OFS $3]++ } END { for (k in c) print k, c[k] }' \
    | sort -t, -k4,4nr -k1,1
} > "$outdir/preemptions_by_job.csv"

# Per month: user x day matrix
tail -n +2 "$raw" | awk -F, -v dir="$outdir" '
function ndays(y, m) {
  if (m == 2) return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28
  return (m == 4 || m == 6 || m == 9 || m == 11) ? 30 : 31
}
{
  ym = substr($5, 1, 7); d = substr($5, 9, 2) + 0
  months[ym] = 1; users[ym, $1] = 1
  c[ym, $1, d]++
}
END {
  for (ym in months) {
    f = dir "/preemptions_" ym ".csv"
    nd = ndays(substr(ym, 1, 4) + 0, substr(ym, 6, 2) + 0)
    hdr = "user"
    for (d = 1; d <= nd; d++) hdr = hdr sprintf(",%s-%02d", ym, d)
    print hdr ",total" > f
    close(f)
    cmd = "sort -t, -k1,1 >> \"" f "\""
    for (k in users) {
      split(k, p, SUBSEP)
      if (p[1] != ym) continue
      row = p[2]; tot = 0
      for (d = 1; d <= nd; d++) { v = c[ym, p[2], d] + 0; row = row "," v; tot += v }
      print row "," tot | cmd
    }
    close(cmd)
  }
}'

echo "Wrote $n preemptions to $outdir:"
ls -1 "$outdir"
