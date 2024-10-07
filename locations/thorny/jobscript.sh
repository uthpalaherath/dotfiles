#!/bin/bash
#SBATCH --job-name=jobname # Job name
#SBATCH --nodes=1             # Run all processes on a single node
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1     # Number of cores per MPI task
#SBATCH --time=800:00:00      # Time limit hrs:min:sec
#SBATCH --partition alromero
#SBATCH --mail-user=ukh0001@mix.wvu.edu
#SBATCH --mail-type=NONE      # Mail events (NONE, BEGIN, END, FAIL, ALL)

source ~/.bashrc
ulimit -s unlimited
module load sched/slurm

cd $WORK_DIR/
time srun -n $NUM_CORES

