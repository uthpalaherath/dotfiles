#!/usr/bin/env bash
# monthly_account_gpu_hours.sh
#
# Per-account GPU-hours for one Slurm partition, as tidy CSV. Emits every
# qualifying account - no top-N truncation, that belongs in the plotting
# step. GPU-only by design: this reporting never covers CPU, so the TRES is
# a constant below rather than a flag.
#
# Runs on the cluster (DCC or NCShare). The usage pass needs nothing but
# sreport and awk, so it works in a bare login environment with no Python.
# The optional efficiency pass additionally needs partition_cpu_gpu_eff.sh
# and the slurm-gpu binary it wraps.
#
# ---------------------------------------------------------------- outputs
#
# One CSV, written to OUTDIR (constant below), stamped with the month range,
# e.g. h200-hp-by-account-2026-05_2026-10.csv. A single-month run
# (-S 2026-10 -E 2026-10) stamps just "2026-10".
#
# One row per account per month:
#
#      month          calendar month, "YYYY-MM"
#      account        Slurm account as sacctmgr has it, e.g. "smithlab_h200"
#      label          account with --strip-suffix removed, e.g. "smithlab"
#      hours          GPU-hours that month, from sreport
#      users          distinct users on the account that month
#      eff_gpu_hours  GPU-hours as slurm-gpu counts them
#      cpu_eff, mem_eff, gpu_eff, gpu_mem_eff
#                     time-weighted averages for that account that month,
#                     from partition_cpu_gpu_eff.sh
#
#   The last six columns are empty without --with-efficiency. The header is
#   the same either way, so the schema never varies.
#
#   sreport also prints a percentage column. It is dropped: whether its
#   denominator respects the Partition= filter was never confirmed, and
#   shares are trivially recomputed from `hours` by whatever consumes this.
#
#   On eff_gpu_hours vs hours: different tools (slurm-gpu and sreport), kept
#   side by side as a cross check. partition_cpu_gpu_eff.sh passes
#   --duplicates, so slurm-gpu counts every run of a requeued job the way
#   sreport does and the two should agree closely. They did NOT before that
#   flag was added: on NCShare's preemptible gpu queue the final-run-only
#   view hid 44% of August 2026's GPU-hours (write-up:
#   RC/DevOps/gpu/ncshare/slurm-gpu-requeued-runs.md). A large gap now means
#   the tooling is wrong, not that work was preempted.
#
# ------------------------------------------------------------------ usage
#
#   monthly_account_gpu_hours.sh -r PARTITION -S YYYY-MM [-E YYYY-MM]
#            [-T TRES] [-s SUFFIX] [-o OUT.csv]
#            [--with-efficiency]
#
#   -r, --partition      Slurm partition (required), e.g. h200-hp
#   -S, --start          first month, YYYY-MM (required)
#   -E, --end            last month, YYYY-MM (default: last complete month)
#   -s, --strip-suffix   suffix to drop for the label column (default: _h200).
#                        Accounts that do NOT end in it are dropped, since
#                        the lab-account convention is <labname>_h200 and
#                        the strays are variants like <labname>_h200_r.
#                        Dropped accounts and their hours are reported on
#                        stderr, never silently discarded.
#       --keep-nonmatching  keep those accounts instead, label = account
#
#   Decision (Nov 2026): on DCC h200-hp this drops two families, both
#   intentionally - <lab>_h200_r (reservations) and <lab>_h200_hp. Together
#   they were 3,132 GPU-hours over Aug-Oct 2026, 7.7% of the partition's
#   accounted total, the bulk of it yaolab_h200_r (1,276) and
#   henaolab_h200_hp (443). The next iteration of the account scheme is
#   meant to use <labname>_h200 only, so the reports follow that convention
#   now rather than carry variants that are about to disappear. Revisit
#   with --keep-nonmatching if a variant turns out to be load-bearing.
#       --with-efficiency   also fill the efficiency columns: one
#                           partition_cpu_gpu_eff.sh run per account per
#                           month (slow, and LOGIN NODES ONLY on the DCC)
#       --eff-script        path to partition_cpu_gpu_eff.sh (default: next
#                           to this script, then $PATH)
#
# Examples:
#   ./monthly_account_gpu_hours.sh -r h200-hp -S 2026-05
#   ./monthly_account_gpu_hours.sh -r h200-hp -S 2026-10 -E 2026-10 --with-efficiency
#
# Note: sreport's End is exclusive at 00:00, so each month's query ends on
# the 1st of the next month, and --end defaults to the last complete month
# because a month queried before it closes undercounts.

set -euo pipefail

# ----------------------------------------------------------------- config

# Where the CSVs go. Not a flag: the same path is mirrored on every cluster
# this runs on, so there is nothing to choose at call time. Create it there
# if it is missing - the script refuses to guess and exits instead.
OUTDIR="/admin/reports/monthly"

# Lab accounts are <labname>_h200; -s overrides.
ACCOUNT_SUFFIX="_h200"

# GPU-hours only - this reporting never covers CPU, so the TRES is fixed
# here rather than exposed as a flag. Change it if that stops being true.
TRES="gres/gpu"

# -------------------------------------------------------------------------

PART=""
START=""
END=""
STRIP_SUFFIX="$ACCOUNT_SUFFIX"
KEEP_NONMATCHING=0
WITH_EFF=0
EFF_SCRIPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--partition)     PART="$2"; shift 2;;
    -S|--start)         START="$2"; shift 2;;
    -E|--end)           END="$2"; shift 2;;
    -s|--strip-suffix)  STRIP_SUFFIX="$2"; shift 2;;
    --keep-nonmatching) KEEP_NONMATCHING=1; shift;;
    --with-efficiency)  WITH_EFF=1; shift;;
    --eff-script)       EFF_SCRIPT="$2"; shift 2;;
    -h|--help)
      sed -n '2,80p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PART" || -z "$START" ]]; then
  echo "Usage: $0 -r PARTITION -S YYYY-MM [-E YYYY-MM] [--with-efficiency]" >&2
  exit 2
fi

if ! command -v sreport >/dev/null 2>&1; then
  echo "sreport not found - run this on the cluster, not the Mac." >&2
  exit 3
fi

[[ "$START" =~ ^[0-9]{4}-[0-9]{2}$ ]] || { echo "--start must be YYYY-MM" >&2; exit 2; }
if [[ -n "$END" ]]; then
  [[ "$END" =~ ^[0-9]{4}-[0-9]{2}$ ]] || { echo "--end must be YYYY-MM" >&2; exit 2; }
else
  END="$(date -d "$(date +%Y-%m-01) -1 day" +%Y-%m)"
fi

if [[ ! -d "$OUTDIR" ]]; then
  echo "output dir '$OUTDIR' does not exist (create it on this cluster)" >&2
  exit 2
fi
if [[ ! -w "$OUTDIR" ]]; then
  echo "output dir '$OUTDIR' is not writable by $(id -un)" >&2
  exit 2
fi
OUTDIR="${OUTDIR%/}"

if [[ "$START" == "$END" ]]; then
  STAMP="$START"
else
  STAMP="${START}_${END}"
fi
OUT="${OUTDIR}/${PART}-by-account-${STAMP}.csv"

if [[ "$START" > "$END" ]]; then
  echo "--start ($START) is after --end ($END)" >&2
  exit 2
fi

if [[ "$END" == "$(date +%Y-%m)" ]]; then
  echo "WARNING: $END is still in progress; its row covers only the days so far." >&2
fi

next_month() { date -d "$1-01 +1 month" +%Y-%m; }
first_of()   { echo "$1-01"; }

# --- 1) usage, from sreport ------------------------------------------------

USAGE_TMP="$(mktemp)"
EFF_TMP="$(mktemp)"
trap 'rm -f "$USAGE_TMP" "$EFF_TMP"' EXIT

month="$START"
while [[ ! "$month" > "$END" ]]; do
  sreport job SizesByAccount FlatView -t hours Grouping= Format=Account%30 \
      Start="$(first_of "$month")" End="$(first_of "$(next_month "$month")")" \
      -T "$TRES" Partition="$PART" --noheader 2>/dev/null \
    | awk -v month="$month" -v suffix="$STRIP_SUFFIX" -v keep="$KEEP_NONMATCHING" '
        {
          account = $1
          hours = $2
          if (account == "" || hours !~ /^[0-9.]+$/) next
          if (account == "(null)") account = "undefined"

          matches = (suffix == "" || index(account, suffix) == length(account) - length(suffix) + 1)
          if (!matches && !keep) {
            dropped[account] += hours
            next
          }

          label = account
          if (matches && suffix != "")
            label = substr(account, 1, length(account) - length(suffix))

          printf "%s,%s,%s,%.2f\n", month, account, label, hours
        }
        END {
          for (a in dropped)
            printf "  dropped %s: %.1f h (does not end in %s)\n", a, dropped[a], suffix > "/dev/stderr"
        }
      ' >> "$USAGE_TMP"

  month="$(next_month "$month")"
done

# --- 2) efficiency, per account per month ---------------------------------
#
# Same granularity as the usage rows above, so the two merge into one row.

if [[ "$WITH_EFF" -eq 1 ]]; then
  if [[ -z "$EFF_SCRIPT" ]]; then
    if [[ -x "$HOME/dotfiles/slurm/utilities/partition_cpu_gpu_eff.sh" ]]; then
      EFF_SCRIPT="$HOME/dotfiles/slurm/utilities/partition_cpu_gpu_eff.sh"
    elif command -v partition_cpu_gpu_eff.sh >/dev/null 2>&1; then
      EFF_SCRIPT="$(command -v partition_cpu_gpu_eff.sh)"
    fi
  fi

  if [[ -z "$EFF_SCRIPT" || ! -x "$EFF_SCRIPT" ]]; then
    echo "ERROR: partition_cpu_gpu_eff.sh not found or not executable. Pass --eff-script PATH." >&2
    exit 4
  fi

  if ! command -v slurm-gpu >/dev/null 2>&1; then
    echo "ERROR: slurm-gpu not on PATH; partition_cpu_gpu_eff.sh wraps it and will produce nothing." >&2
    echo "       On the DCC it is installed on the LOGIN nodes only, so --with-efficiency has to" >&2
    echo "       run there; a compute-node shell (srun/salloc/agent alias) will not find it." >&2
    exit 4
  fi

  mapfile -t PAIRS < <(awk -F, '$2 != "undefined" { print $1 " " $2 }' "$USAGE_TMP" | sort -u)
  total=${#PAIRS[@]}
  i=0
  for pair in "${PAIRS[@]}"; do
    read -r month acct <<< "$pair"
    i=$((i + 1))
    printf '[%d/%d] %s %s\n' "$i" "$total" "$month" "$acct" >&2

    "$EFF_SCRIPT" -r "$PART" -S "$(first_of "$month")" \
        -E "$(first_of "$(next_month "$month")")" -A "$acct" 2>/dev/null \
      | awk -v key="$month,$acct" '
          /^No\. of users:/  { users = $NF }
          /^Total GPU-hours:/ { gpuhrs = $NF }
          /Avg CPU Eff:/     { cpu = $NF }
          /Avg Mem Eff:/     { mem = $NF }
          /Avg GPU Eff:/     { gpu = $NF }
          /Avg GPU Mem Eff:/ { gpumem = $NF }
          END {
            gsub(/%/, "", cpu); gsub(/%/, "", mem); gsub(/%/, "", gpu); gsub(/%/, "", gpumem)
            printf "%s,%s,%s,%s,%s,%s,%s\n", key,
                   (users  == "" ? "" : users),
                   (gpuhrs == "" ? "" : gpuhrs),
                   (cpu    == "" || cpu    == "n/a" ? "" : cpu),
                   (mem    == "" || mem    == "n/a" ? "" : mem),
                   (gpu    == "" || gpu    == "n/a" ? "" : gpu),
                   (gpumem == "" || gpumem == "n/a" ? "" : gpumem)
          }' >> "$EFF_TMP"
  done
fi

# --- 3) one CSV, usage joined to efficiency -------------------------------

echo "month,account,label,hours,users,eff_gpu_hours,cpu_eff,mem_eff,gpu_eff,gpu_mem_eff" > "$OUT"
# NB: keyed off FILENAME, not the usual NR==FNR - with no --with-efficiency
# the first file is empty, and then NR==FNR stays true through the second
# file and silently eats every row.
awk -F, -v OFS=, -v efffile="$EFF_TMP" '
  FILENAME == efffile { eff[$1 "," $2] = $3 OFS $4 OFS $5 OFS $6 OFS $7 OFS $8; next }
  {
    key = $1 "," $2
    print $0, (key in eff ? eff[key] : ",,,,,")
  }
' "$EFF_TMP" "$USAGE_TMP" | sort -t, -k1,1 -k4,4gr >> "$OUT"

rows=$(($(wc -l < "$OUT") - 1))
echo "Wrote $OUT: $rows rows" >&2
