#!/bin/bash
#SBATCH -J jobname
#SBATCH -A m3337_g
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH -t 12:00:00
#SBATCH --nodes 1
#SBATCH --ntasks-per-node=64
#SBATCH -c 2 #<Thread number for each job = 2*(64/ntasks-per-node)>
#SBATCH --gpus-per-node 4
#SBATCH --gpu-bind=none
#SBATCH --mail-user=uthpala.herath@duke.edu
#SBATCH --mail-type=END,FAIL

source ~/.bashrc
ulimit -s unlimited

nvidia-cuda-mps-control -d
export SLURM_CPU_BIND="cores"
#export SLURM_CPU_BIND="threads"

cd $WORK_DIR/
time srun -n $NUM_CORES ~/dotfiles/locations/perlmutter/pass_to_slurm.sh aims.x > aims.out 2> aims.error
