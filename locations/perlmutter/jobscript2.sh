#!/bin/bash
#SBATCH -J jobname
#SBATCH -A m3337_g
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH -t 12:00:00
#SBATCH --nodes 2
#SBATCH --ntasks-per-node=64
#SBATCH -c 2 #<Thread number for each job = 2*(64/ntasks-per-node)>
#SBATCH --gpus-per-task 1
#SBATCH --gpu-bind=verbose

##SBATCH --gpus-per-node 4

source ~/.bashrc
ulimit -s unlimited

nvidia-cuda-mps-control -d
export SLURM_CPU_BIND="cores"
#export SLURM_CPU_BIND="threads"

cd $WORK_DIR/
time srun --cpu-bind=verbose nsys profile -o profile.%q{LOCAL_RANK} -t cuda,nvtx,osrt -s none -n $NUM_CORES ~/dotfiles/locations/perlmutter/pass_to_slurm.sh aims.x > aims.out 2> aims.error
