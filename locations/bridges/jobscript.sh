#!/bin/bash
#SBATCH -N 2
#SBATCH --ntasks-per-node=28
#SBATCH -t 48:00:00
##SBATCH --mem=10GB
##SBATCH -p RM-shared #### RM-small, LM

#echo commands to stdout
set -x

# execution
ulimit -s unlimited
cd $SLURM_SUBMIT_DIR/
mpirun -np $SLURM_NTASKS

