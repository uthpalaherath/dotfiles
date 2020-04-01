#!/bin/bash
#SBATCH -N 2 
###SBATCH -p RM-shared #### RM-small, LM
#SBATCH -t 48:00:00
###SBATCH --mem=10GB

#echo commands to stdout
set -x

# move to working directory
# this job assumes:
# - all input data is stored in this directory 
# - all output should be stored in this directory

ulimit -s unlimited
cd $SLURM_SUBMIT_DIR/DFT/
time mpirun -np 56 vasp_std
cp CONTCAR ../POSCAR
cd ..
time python2 RUNDMFT.py
echo "Done"

