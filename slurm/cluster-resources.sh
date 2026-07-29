#!/usr/bin/env bash
#
# cluster-resources.sh - Summarize total nodes, CPUs, and GPUs on a Slurm cluster.
#
# Usage:
#   ./cluster-resources.sh                 # summarize the whole cluster
#   ./cluster-resources.sh -p PART         # limit to a specific partition
#   ./cluster-resources.sh -c              # compute nodes only (exclude utility)
#   ./cluster-resources.sh --compute-only  # same as -c
#
set -euo pipefail

# Regex matching utility/admin node names to exclude in --compute-only mode.
# These are service hosts (login, file transfer, on-demand, CryoSPARC portals),
# not schedulable compute nodes.
UTILITY_RE='NodeName=dcc-(login|fsutil|xfer|ondemand|stat-ondemand|cryosparc)'

partition=""
compute_only=0

# Normalize the long option to the short one before getopts.
args=()
for a in "$@"; do
  case "$a" in
    --compute-only) args+=("-c") ;;
    *)              args+=("$a") ;;
  esac
done
set -- "${args[@]}"

while getopts ":p:ch" opt; do
  case "$opt" in
    p) partition="$OPTARG" ;;
    c) compute_only=1 ;;
    h)
      echo "Usage: $0 [-p PARTITION] [-c|--compute-only]"
      exit 0
      ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Build the node list. If a partition is given, restrict to its nodes.
if [[ -n "$partition" ]]; then
  nodes=$(sinfo -h -p "$partition" -N -o "%N" | sort -u)
  if [[ -z "$nodes" ]]; then
    echo "No nodes found for partition '$partition'." >&2
    exit 1
  fi
  info=$(scontrol -o show nodes "$(echo "$nodes" | paste -sd,)")
  scope="partition '$partition'"
else
  info=$(scontrol -o show nodes)
  scope="entire cluster"
fi

# Optionally drop utility/admin nodes so counts reflect real compute capacity.
if [[ "$compute_only" -eq 1 ]]; then
  info=$(echo "$info" | grep -vP "$UTILITY_RE")
  scope="${scope}, compute nodes only"
  if [[ -z "$info" ]]; then
    echo "No compute nodes remain after excluding utility nodes." >&2
    exit 1
  fi
fi

# Node count
node_count=$(echo "$info" | grep -c 'NodeName=')

# Total CPUs (configured)
cpu_count=$(echo "$info" | grep -oP 'CPUTot=\d+' | awk -F= '{s+=$2} END {print s+0}')

# Total GPUs (parsed from the Gres=gpu:... field)
gpu_count=$(echo "$info" | grep -oP 'Gres=gpu:\S+' | sed -E 's/\(.*//' \
            | awk -F: '{s+=$NF} END {print s+0}')

echo "Slurm resource summary (${scope}):"
printf "  %-12s %s\n" "Nodes:" "$node_count"
printf "  %-12s %s\n" "CPUs:"  "$cpu_count"
printf "  %-12s %s\n" "GPUs:"  "$gpu_count"
echo
echo "GPUs by type:"
echo "$info" | grep -oP 'Gres=gpu:\S+' | sed -E 's/Gres=gpu://; s/\(.*//' \
  | awk -F: '{sum[$1]+=$NF} END {for (t in sum) printf "  %-28s %d\n", t, sum[t]}' \
  | sort -k2 -nr
