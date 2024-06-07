#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH -N 1
#SBATCH --ntasks-per-node=20
#SBATCH --cpus-per-task=2
#SBATCH -q long
#SBATCH -t 800:00:00

# initialization
source ~/.bashrc
ulimit -s unlimited
intel

# execution
cd $WORK_DIR/
srun -n $NUM_CORES aims.x > aims.out 2>aims.err
