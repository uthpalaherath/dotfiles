#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH -N 1
#SBATCH --ntasks-per-node=20
#SBATCH --cpus-per-task=2
#SBATCH -q long
#SBATCH -t 800:00:00

# initialization
source ~/.bashrc
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0

# execution
cd $WORK_DIR/
#time mpirun -np $SLURM_NTASKS
time srun --cpu-bind=cores -n $NUM_CORES aims.x > aims.out 2>aims.err
