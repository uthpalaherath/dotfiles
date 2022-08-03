#!/bin/bash
# select_cpu_device wrapper script
export CUDA_VISIBLE_DEVICES=$(( SLURM_LOCALID % 4 ))
exec $*
