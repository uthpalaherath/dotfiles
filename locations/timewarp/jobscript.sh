#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH -N 1
#SBATCH --ntasks-per-node=20
#SBATCH --cpus-per-task=2
#SBATCH -q long
#SBATCH -t 72:00:00

# initialization
source ~/.bashrc
ulimit -s unlimited
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0

# execution
cd $WORK_DIR/
#time mpirun -np $SLURM_NTASKS
time srun --cpu-bind=cores -n $NUM_CORES aims.x </dev/null > aims.out 2>&1


