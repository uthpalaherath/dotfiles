#!/bin/bash
#PBS -N jobname
#PBS -q comm_small_week #comm_small_day
#PBS -l walltime=168:00:00
#PBS -l nodes=4:ppn=40 #,pvmem=8gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe

NUM_CORES=$(($PBS_NUM_NODES*$PBS_NUM_PPN))

source ~/.bashrc
ulimit -s unlimited
cd $PBS_O_WORKDIR
time mpirun -np $NUM_CORES

