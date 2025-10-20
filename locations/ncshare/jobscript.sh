#!/bin/bash
#SBATCH -J myjob             # Job name
#SBATCH -p common         # Queue (partition) name
#SBATCH -N 1                 # Total # of nodes
#SBATCH --ntasks-per-node 64 # Tasks per node
#SBATCH -c 2                 # CPU's per task
#SBATCH --mem=503G           # Memory per node
#SBATCH --mail-type=fail     # Send email at failed job
#SBATCH --mail-type=end      # Send email at end of job
#SBATCH --mail-user=uthpala.herath@duke.edu

# Initialization
source ~/.bashrc

cd $SLURM_SUBMIT_DIR
mpirun -n $SLURM_NTASKS aims.x > aims.out 2> aims.err
