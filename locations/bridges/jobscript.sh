#!/bin/bash
#SBATCH -N 2
###SBATCH -p RM-shared #### RM-small, LM
#SBATCH -t 48:00:00
###SBATCH --mem=10GB

#echo commands to stdout
set -x

# execution
ulimit -s unlimited
cd $SLURM_SUBMIT_DIR/

