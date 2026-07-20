#!/usr/bin/env bash
# partition_cpu_gpu_eff_gpuutil.sh
#
# Run partition_cpu_gpu_eff.sh with partition GPU Eff calculated from each
# user's elapsed-time-weighted GPUUtil:
#
#   sum(user elapsed hours * user GPUUtil) / total GPU-hours
#
# Because GPUUtil includes GPU count, this produces a direct GPU-hour-weighted
# partition GPU efficiency when users run jobs with different GPU counts.
# Per-user values and the CPU, memory, and GPU-memory partition calculations
# remain unchanged.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PARTITION_GPU_EFF_USE_GPUUTIL=1
export PARTITION_REPORT_COMMAND="${0##*/}"

exec "$SCRIPT_DIR/partition_cpu_gpu_eff.sh" "$@"
