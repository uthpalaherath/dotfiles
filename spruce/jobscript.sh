#!/bin/bash
#PBS -N job
#PBS -q alromero #comm_256g_mem 
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=16,pvmem=8gb ####:broadwell:large,pvmem=20gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe
#PBS -e $PBS_O_WORKDIR/OUTPUT.error
#PBS -o $PBS_O_WORKDIR/OUTPUT.output

source ~/.bashrc
ulimit -s unlimited
cd $PBS_O_WORKDIR
time python RUNDMFT.py  
echo 'Done'

