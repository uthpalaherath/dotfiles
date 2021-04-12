#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH -N 1
#SBATCH --ntasks-per-node=64
#SBATCH -t 72:00:00
##SBATCH --mem=10GB
##SBATCH -p RM-shared #### RM-small, LM

#echo commands to stdout
set -x

# execution
ulimit -s unlimited
cd $SLURM_SUBMIT_DIR/
time mpirun -np $SLURM_NTASKS
