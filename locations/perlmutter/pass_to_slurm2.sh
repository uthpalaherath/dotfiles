#!/bin/bash
# select_cpu_device wrapper script
# export CUDA_VISIBLE_DEVICES=$(( SLURM_LOCALID % 4 ))
nsys profile -o profile.%q{LOCAL_RANK} -t cuda,nvtx,osrt -s none --stats=true
exec $*
