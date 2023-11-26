#!/bin/bash
#SBATCH -N 1
#SBATCH --tasks-per-node=68
#SBATCH -C knl,quad,cache
#SBATCH -p regular
#SBATCH -J jobname
#SBATCH -t 48:00:00
#SBATCH -A m3337

source ~/.bashrc
ulimit -s unlimited
export SLURM_CPU_BIND="cores"

cd $WORK_DIR/
time srun -n $NUM_CORES --cpu_bind=cores ~/local/FHIaims_cori/build/aims.x > aims.out 2> aims.err
