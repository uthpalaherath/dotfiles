#!/usr/bin/env bash
set -euo pipefail

partition="gpu"

usage() {
  printf 'Usage: %s [-p partition]\n' "$(basename "$0")"
}

while getopts ":p:h" opt; do
  case "$opt" in
    p)
      partition="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    :)
      printf 'Missing argument for -%s\n' "$OPTARG" >&2
      usage >&2
      exit 2
      ;;
    \?)
      printf 'Unknown option: -%s\n' "$OPTARG" >&2
      usage >&2
      exit 2
      ;;
  esac
done

squeue_tmp=$(mktemp)
sprio_tmp=$(mktemp)
sshare_tmp=$(mktemp)
report_tmp=$(mktemp)
summary_tmp=$(mktemp)

cleanup() {
  rm -f "$squeue_tmp" "$sprio_tmp" "$sshare_tmp" "$report_tmp" "$summary_tmp"
}

trap cleanup EXIT

squeue -h -p "$partition" -t PD -o "%i|%u|%V|%r|%b|%m|%l" > "$squeue_tmp"

if [[ ! -s "$squeue_tmp" ]]; then
  printf "No pending jobs found on partition '%s'.\n" "$partition"
  exit 0
fi

sprio -p "$partition" -l > "$sprio_tmp"
users=$(squeue -h -p "$partition" -t PD -o "%u" | sort -u | paste -sd, -)
sshare -n -P -u "$users" -o User,Account,FairShare > "$sshare_tmp"

awk -F'|' -v spriofile="$sprio_tmp" -v ssharefile="$sshare_tmp" '
  function trim(s) {
    gsub(/^ +| +$/, "", s)
    return s
  }
  function fmt_wait(ts,   t, parts, diff, days, hours, mins, out) {
    split(ts, parts, /[-T:]/)
    if (length(parts) != 6) {
      return "NA"
    }
    t = mktime(parts[1] " " parts[2] " " parts[3] " " parts[4] " " parts[5] " " parts[6])
    if (t <= 0) {
      return "NA"
    }
    diff = systime() - t
    if (diff < 0) {
      diff = 0
    }
    days = int(diff / 86400)
    hours = int((diff % 86400) / 3600)
    mins = int((diff % 3600) / 60)
    out = ""
    if (days > 0) {
      out = out days "d"
    }
    if (days > 0 || hours > 0) {
      out = out hours "h"
    }
    out = out mins "m"
    return out
  }
  BEGIN {
    while ((getline line < spriofile) > 0) {
      line = trim(line)
      if (line == "" || line ~ /^JOBID[[:space:]]/) {
        continue
      }

      split(line, f, /[[:space:]]+/)
      jobid = f[1]
      account[jobid] = f[4]
      priority[jobid] = f[5]
      age[jobid] = f[7]
      fs_score[jobid] = f[9]
      jobsize[jobid] = f[10]
      qosname[jobid] = f[12]
    }
    close(spriofile)

    while ((getline line < ssharefile) > 0) {
      if (line == "") {
        continue
      }

      split(line, f, "|")
      user = trim(f[1])
      acct = trim(f[2])
      fairshare = trim(f[3])

      if (user == "" || acct == "") {
        continue
      }

      raw_fairshare[user SUBSEP acct] = fairshare
    }
    close(ssharefile)
  }
  {
    jobid = $1
    user = $2
    submit = $3
    acct = (jobid in account ? account[jobid] : "NA")
    raw_fs = ((user SUBSEP acct) in raw_fairshare ? raw_fairshare[user SUBSEP acct] : "NA")
    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n", \
      user, \
      acct, \
      submit, \
      fmt_wait(submit), \
      jobid, \
      (jobid in priority ? priority[jobid] : "NA"), \
      (jobid in fs_score ? fs_score[jobid] : "NA"), \
      raw_fs, \
      (jobid in age ? age[jobid] : "NA"), \
      (jobid in jobsize ? jobsize[jobid] : "NA"), \
      (jobid in qosname ? qosname[jobid] : "NA"), \
      $4, \
      $5, \
      $6, \
      $7
  }
' "$squeue_tmp" > "$report_tmp"

awk -F'|' '
  {
    user = $1
    count[user]++
    account[user] = $2
    if (!(user in top_priority) || $6 + 0 > top_priority[user]) {
      top_priority[user] = $6 + 0
    }
    if (!(user in low_priority) || $6 + 0 < low_priority[user]) {
      low_priority[user] = $6 + 0
    }
    fs_score[user] = $7
    raw_fairshare[user] = $8
    first_submit[user] = (count[user] == 1 || $3 < first_submit[user]) ? $3 : first_submit[user]
    last_submit[user] = (count[user] == 1 || $3 > last_submit[user]) ? $3 : last_submit[user]
  }
  END {
    for (user in count) {
      printf "%s|%s|%d|%d|%d|%s|%s|%s|%s\n", \
        user, account[user], count[user], top_priority[user], low_priority[user], fs_score[user], raw_fairshare[user], first_submit[user], last_submit[user]
    }
  }
' "$report_tmp" | sort -t'|' -k4,4nr -k3,3nr > "$summary_tmp"

printf "Pending jobs on partition '%s'\n\n" "$partition"

printf "User summary\n\n"
awk -F'|' '
  function clip(s, width) {
    if (length(s) <= width) {
      return s
    }
    return substr(s, 1, width - 3) "..."
  }
  BEGIN {
    printf "%-18s %-10s %-12s %-12s %-12s %-10s %-14s %-19s %-19s\n", \
      "USER", "ACCOUNT", "PENDING_JOBS", "TOP_PRIORITY", "LOW_PRIORITY", "FS_SCORE", "RAW_FAIRSHARE", "OLDEST_SUBMIT", "NEWEST_SUBMIT"
  }
  {
    printf "%-18s %-10s %12s %12s %12s %10s %14s %-19s %-19s\n", \
      clip($1, 18), clip($2, 10), $3, $4, $5, $6, $7, clip($8, 19), clip($9, 19)
  }
' "$summary_tmp"

printf "\nDetailed jobs\n\n"
sort -t'|' -k6,6nr -k1,1 -k5,5n "$report_tmp" | awk -F'|' '
  function clip(s, width) {
    if (length(s) <= width) {
      return s
    }
    return substr(s, 1, width - 3) "..."
  }
  function shorten_reason(s, width) {
    gsub(/[[:space:]]+/, "_", s)
    return clip(s, width)
  }
  BEGIN {
    printf "%-18s %-10s %-8s %-8s %-9s %-8s %-13s %-28s %-18s %-8s %-10s\n", \
      "USER", "ACCOUNT", "WAIT", "JOBID", "PRIORITY", "FS_SCORE", "RAW_FAIRSHARE", "REASON", "GRES", "MEM", "TIMELIMIT"
  }
  {
    printf "%-18s %-10s %-8s %-8s %9s %8s %13s %-28s %-18s %-8s %-10s\n", \
      clip($1, 18), clip($2, 10), clip($4, 8), clip($5, 8), $6, $7, $8, shorten_reason($12, 28), clip($13, 18), clip($14, 8), clip($15, 10)
  }
'

printf "\nNotes:\n"
printf '%s\n' '- Detailed jobs are sorted globally by PRIORITY, highest first.'
printf '%s\n' '- WAIT is time since submit; PRIORITY is the per-job score Slurm schedules on.'
printf '%s\n' '- RAW_FAIRSHARE is the underlying user/account fairshare value from sshare.'
printf '%s\n' ''
printf '%s\n' 'PRIORITY = PARTITION_SCORE + FS_SCORE + AGE_SCORE + JOBSIZE_SCORE + QOS_SCORE + SITE_SCORE + ASSOC_SCORE + NICE_ADJUSTMENT'
printf '%s\n' ''
printf '%s\n' '- PARTITION_SCORE: boost from the partition priority tier/weight.'
printf '%s\n' '- FS_SCORE: fairshare contribution to per-job priority from sprio.'
printf '%s\n' '- AGE_SCORE: boost from how long the job has been eligible and waiting.'
printf '%s\n' '- JOBSIZE_SCORE: boost based on the requested job size.'
printf '%s\n' '- QOS_SCORE: boost or penalty from the job QoS.'
printf '%s\n' '- SITE_SCORE: site-defined priority component, often zero.'
printf '%s\n' '- ASSOC_SCORE: association/account priority component, often zero.'
printf '%s\n' '- NICE_ADJUSTMENT: user/admin nice value that lowers or raises priority.'
