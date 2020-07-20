#!/bin/bash
#PBS -N job
#PBS -q alromero ##comm_256g_mem
#PBS -l walltime=168:00:00
#PBS -l nodes=1:ppn=16,pvmem=8gb ####:broadwell:large,pvmem=20gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe

NUM_CORES=$(($PBS_NUM_NODES*$PBS_NUM_PPN))

source ~/.bashrc
ulimit -s unlimited
cd $PBS_O_WORKDIR
mpirun -np $NUM_CORES

