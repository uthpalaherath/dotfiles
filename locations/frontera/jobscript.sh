#!/bin/bash
#SBATCH -J myjob             # Job name
#SBATCH -p normal            # Queue (partition) name
#SBATCH -N 1                 # Total # of nodes
#SBATCH --ntasks-per-node 56 # Tasks per node
#SBATCH -t 48:00:00          # Run time (hh:mm:ss)
#SBATCH -A DMR23007          # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-type=fail     # Send email at failed job
#SBATCH --mail-type=end      # Send email at end of job
#SBATCH --mail-user=uthpala.herath@duke.edu

source ~/.bashrc
ulimit -s unlimited

cd $WORK_DIR/
time ibrun aims.x > aims.out 2> aims.err
