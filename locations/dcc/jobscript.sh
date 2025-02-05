#!/bin/bash
#SBATCH -J myjob             # Job name
#SBATCH -p scavenger         # Queue (partition) name
#SBATCH -N 1                 # Total # of nodes
#SBATCH --ntasks-per-node 42 # Tasks per node
#SBATCH -c 2                 # CPU's per task
#SBATCH --mem-per-cpu=5G     # Memory per CPU
#SBATCH --mail-type=fail     # Send email at failed job
#SBATCH --mail-type=end      # Send email at end of job
#SBATCH --mail-user=uthpala.herath@duke.edu

## OTHER
##SBATCH -n 84                # Total # of tasks
##SBATCH --mem=466G           # Memory per node

# Initialization
source ~/.bashrc

cd $SLURM_SUBMIT_DIR
mpirun -n $SLURM_NTASKS aims.x > aims.out 2> aims.err
