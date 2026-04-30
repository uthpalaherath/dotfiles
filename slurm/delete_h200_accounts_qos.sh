#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./delete_h200_accounts_qos.sh       # prompts for confirmation on each sacctmgr call
#   ./delete_h200_accounts_qos.sh -i    # non-interactive mode

SACCTMGR_FLAGS=()
if [[ "${1:-}" == "-i" ]]; then
  SACCTMGR_FLAGS=(-i)
fi

labs=(
    szhoulab
)

for n in "${labs[@]}"; do
  sacctmgr "${SACCTMGR_FLAGS[@]}" delete Account "${n}_h200,${n}_h200_r" && \
  sacctmgr "${SACCTMGR_FLAGS[@]}" delete QOS "${n}_h200"
done
