#!/usr/bin/env bash
# Comprehensive memory diagnostics with correct raw units and GiB summaries.
# Safe for non-root users on HPC clusters.
#
# Author: Uthpala Herath and ChatGPT

set -euo pipefail

sep(){ printf '%0.s-' $(seq 1 72); printf '\n'; }
timestamp(){ printf 'Report generated: %s\n' "$(date --iso-8601=seconds)"; }
has_cmd(){ command -v "$1" >/dev/null 2>&1; }

# Convert numeric bytes -> GiB with 2 decimals, otherwise print label as-is
to_gib() {
  local v="$1"
  if [[ -z "$v" || "$v" == "max" || "$v" == "unlimited" || "$v" == "-" || "$v" == "N/A" ]]; then
    printf "%s" "$v"; return
  fi
  if ! [[ "$v" =~ ^[0-9]+$ ]]; then
    printf "%s" "$v"; return
  fi
  awk -v b="$v" 'BEGIN{printf "%.2f GiB", b/1024/1024/1024}'
}

# Extract soft value (may be numeric or words) for a label from /proc/self/limits
# This picks the field $(NF-2) which is the "soft" value in the usual limits table format.
extract_limit_any() {
  local label="$1"
  if [ -f /proc/self/limits ]; then
    awk -v pat="$label" 'BEGIN{IGNORECASE=1} $0 ~ pat {
      # soft field is typically at NF-2; print it
      if (NF>=3) { print $(NF-2); exit }
    }' /proc/self/limits 2>/dev/null || true
  fi
}

# Fallback: use prlimit output (if available) to get AS/MEM values
prlimit_extract_any() {
  local label="$1"
  if has_cmd prlimit; then
    prlimit --pid $$ 2>/dev/null | awk -v pat="$label" 'BEGIN{IGNORECASE=1}
      $0 ~ pat {
        # prlimit table: RESOURCE DESCRIPTION SOFT HARD UNITS
        # the soft column is the 3rd column in prlimit output
        if (NF>=3) { print $3; exit }
      }' || true
  fi
}

# ---------------- header ----------------
sep
echo "MEMORY DIAGNOSTICS"
timestamp
sep

# ---------------- node memory ----------------
echo
echo "Node memory"
sep
if has_cmd free; then
  free -h
else
  awk '/MemTotal|MemFree|MemAvailable/ {printf "%s: %s\n", $1, $2}' /proc/meminfo
fi

# ---------------- cgroup info ----------------
echo
echo "Cgroup memory info:"
sep
cgpath=$(cut -d: -f3 /proc/self/cgroup | sed -n '1p' || true)
[ -z "$cgpath" ] && cgpath="/"
cg2="/sys/fs/cgroup${cgpath}"
cg1="/sys/fs/cgroup/memory${cgpath}"

cgroup_mem_max="N/A"
cgroup_mem_cur="N/A"
cgroup_raw_unit="bytes"

if [ -f "${cg2}/memory.max" ]; then
  cgroup_mem_max=$(cat "${cg2}/memory.max" 2>/dev/null || echo "N/A")
  cgroup_mem_cur=$(cat "${cg2}/memory.current" 2>/dev/null || echo "N/A")
  echo "Detected cgroup v2: ${cg2}"
  printf " memory.max:     %-12s (raw: %s %s)\n"   "$(to_gib "$cgroup_mem_max")" "$cgroup_mem_max" "$cgroup_raw_unit"
  printf " memory.current: %-12s (raw: %s %s)\n"   "$(to_gib "$cgroup_mem_cur")" "$cgroup_mem_cur" "$cgroup_raw_unit"
elif [ -f "${cg1}/memory.limit_in_bytes" ]; then
  cgroup_mem_max=$(cat "${cg1}/memory.limit_in_bytes" 2>/dev/null || echo "N/A")
  cgroup_mem_cur=$(cat "${cg1}/memory.usage_in_bytes" 2>/dev/null || echo "N/A")
  echo "Detected cgroup v1: ${cg1}"
  printf " memory.limit_in_bytes: %-12s (raw: %s %s)\n" "$(to_gib "$cgroup_mem_max")" "$cgroup_mem_max" "$cgroup_raw_unit"
  printf " memory.usage_in_bytes: %-12s (raw: %s %s)\n" "$(to_gib "$cgroup_mem_cur")" "$cgroup_mem_cur" "$cgroup_raw_unit"
else
  echo "No cgroup memory files found at ${cg2} or ${cg1}."
fi

# ---------------- process limits ----------------
echo
echo "Per-process limits (RSS, AS, MEMLOCK):"
sep

# Try /proc/self/limits first, fallback to prlimit
rss_val=$(extract_limit_any "Max resident set")
if [ -z "$rss_val" ]; then rss_val=$(prlimit_extract_any "^AS?S?"); fi
as_val=$(extract_limit_any "Max address space")
if [ -z "$as_val" ]; then as_val=$(prlimit_extract_any "^AS"); fi
mlock_val=$(extract_limit_any "Max locked memory")
if [ -z "$mlock_val" ]; then mlock_val=$(prlimit_extract_any "MEMLOCK"); fi

# Normalize empty -> '-'
rss_val=${rss_val:--}
as_val=${as_val:--}
mlock_val=${mlock_val:--}

# Units for raw values (these limits are expressed in bytes per /proc/self/limits)
raw_unit_limits="bytes"

printf " Max resident set (RSS) : %-10s  (raw: %s %s)\n" "$(to_gib "$rss_val")" "${rss_val:--}" "$raw_unit_limits"
printf " Max address space (AS) : %-10s  (raw: %s %s)\n" "$(to_gib "$as_val")" "${as_val:--}" "$raw_unit_limits"
printf " Max locked memory      : %-10s  (raw: %s %s)\n" "$(to_gib "$mlock_val")" "${mlock_val:--}" "$raw_unit_limits"

echo
echo "Full per-process info (prlimit | ulimit -a | /proc/self/limits):"
sep
if has_cmd prlimit; then
  echo "prlimit --pid $$:"
  prlimit --pid $$ || true
  echo
fi
echo "ulimit -a:"
bash -lc 'ulimit -a' || true
echo
echo "/proc/self/limits (relevant lines):"
grep -E "Max resident set|Max address space|Max locked memory" /proc/self/limits || cat /proc/self/limits

# ---------------- kernel logs ----------------
echo
echo "Kernel OOM | kill messages:"
sep
found=false
if has_cmd journalctl; then
  journalctl -k -n 200 --no-pager 2>/dev/null | egrep -i 'oom|killed process|out of memory' && found=true || true
fi
if has_cmd dmesg && ! $found; then
  dmesg --ctime 2>/dev/null | tail -n 200 | egrep -i 'oom|killed process|out of memory' && found=true || true
fi
if ! $found; then
  echo "(no OOM messages found or insufficient permissions)"
fi

# ---------------- Slurm context ----------------
echo
echo "Slurm context (if any):"
sep
if [ -n "${SLURM_JOB_ID:-}" ]; then
  echo "SLURM_JOB_ID=$SLURM_JOB_ID"
  if has_cmd scontrol; then
    scontrol show job "$SLURM_JOB_ID" || true
  fi
  echo "To check job memory after completion:"
  echo "  sacct -j $SLURM_JOB_ID --format=JobID,State,MaxRSS,MaxVMSize"
else
  echo "No SLURM_JOB_ID in environment."
fi

# ---------------- SUMMARY ----------------
echo
sep
echo "SUMMARY"
sep
if has_cmd free && free -b >/dev/null 2>&1; then
  node_bytes=$(free -b | awk '/^Mem:/ {print $2}')
  printf " Node total memory     : %-10s  (raw: %s bytes)\n" "$(to_gib "$node_bytes")" "$node_bytes"
else
  echo " Node total memory     : (see 'free -h' output above)"
fi
printf " cgroup memory.max     : %-10s  (raw: %s %s)\n" "$(to_gib "$cgroup_mem_max")" "$cgroup_mem_max" "$cgroup_raw_unit"
printf " cgroup memory.current : %-10s  (raw: %s %s)\n" "$(to_gib "$cgroup_mem_cur")" "$cgroup_mem_cur" "$cgroup_raw_unit"
printf " per-process RSS limit : %-10s  (raw: %s %s)\n" "$(to_gib "$rss_val")" "$rss_val" "$raw_unit_limits"
printf " per-process AS limit  : %-10s  (raw: %s %s)\n" "$(to_gib "$as_val")" "$as_val" "$raw_unit_limits"
printf " per-process MEMLOCK   : %-10s  (raw: %s %s)\n" "$(to_gib "$mlock_val")" "$mlock_val" "$raw_unit_limits"
sep
exit 0
