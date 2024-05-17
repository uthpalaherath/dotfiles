#!/bin/bash
#SBATCH -J myjob             # Job name
#SBATCH -p rtx            # Queue (partition) name
#SBATCH -N 1                 # Total # of nodes
#SBATCH --ntasks-per-node 16 # Tasks per node
#SBATCH -t 48:00:00          # Run time (hh:mm:ss)
#SBATCH -A DMR23007          # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-type=fail     # Send email at failed job
#SBATCH --mail-type=end      # Send email at end of job
#SBATCH --mail-user=uthpala.herath@duke.edu

source ~/.bashrc
ulimit -s unlimited
intel

nvidia-cuda-mps-control -d
export SLURM_CPU_BIND="cores"

cd $WORK_DIR/
ibrun /home1/05979/uthpala/dotfiles/locations/frontera/pass_to_slurm.sh aims_gpu.x > aims.out 2> aims.err
