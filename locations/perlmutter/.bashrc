# .bashrc for perlmutter (perlmutter-p1.nersc.gov)
# and cori (cori.nersc.gov)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

module purge

#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Source for colorful terminal
source ~/.bash_prompt

# tmux
if [[ $NERSC_HOST="cori" ]]; then
    export TMUX_DEVICE_NAME=cori
else
    export TMUX_DEVICE_NAME=perlmutter
fi

# Launch tmux
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
    #tmux
fi

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# ENV
NUM_CORES=$SLURM_NTASKS
WORK_DIR=$SLURM_SUBMIT_DIR

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

if [[ $NERSC_HOST="cori" ]]; then
    export FC=mpiifort
    export CC=mpiicc
    export CXX=mpiicpc
else
    export FC=ftn
    export CC=cc
    export CXX=CC
fi

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u uthpala --format="%.18i %.9P %50j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact="salloc --nodes 1 --ntasks-per-node=128 --qos interactive --time 04:00:00 --constraint cpu --account=m3337 --cpus-per-task=2"
alias interact_gpu="salloc --nodes 1 --ntasks-per-node=64 --qos interactive --time 04:00:00 --constraint gpu --gpus 4 --account=m3337_g --cpus-per-task=2"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from perlmutter" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"

if [[ $NERSC_HOST="cori" ]]; then
    alias scratch="cd $SCRATCH"
    alias makejob="cp ~/dotfiles/locations/perlmutter/jobscript_cori.sh ./jobscript.sh"
else
    alias scratch="cd $PSCRATCH"
    alias makejob="cp ~/dotfiles/locations/perlmutter/jobscript.sh ."
fi

#------------------------------------------- MODULES -------------------------------------------

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE

if [[ $NERSC_HOST="cori" ]]; then
    module load PrgEnv-intel/6.0.10
    module load craype/2.7.10
    module load gcc/11.2.0
    module load intel/19.1.2.254
    module load impi/2020.up4

else
    module load PrgEnv-gnu >/dev/null
    module load craype/2.7.13 >/dev/null
    module load gcc/10.3.0 >/dev/null
    module load cray-mpich/8.1.13 >/dev/null
    module load cudatoolkit/11.7 >/dev/null
    module load craype-accel-nvidia80 >/dev/null
    module load cray-libsci/21.08.1.2

    module load craype-x86-milan
    module load cray-fftw/3.3.8.13

    # CUDA
    export CRAY_ACCEL_TARGET=nvidia80
    export LIBRARY_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$LIBRARY_PATH"
    export LD_LIBRARY_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="${CUDATOOLKIT_HOME}/lib64/:$LD_LIBRARY_PATH"
    export CPATH="${CUDATOOLKIT_HOME}/../../math_libs/include:$CPATH"
    export CUDA_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$CUDA_PATH"
fi

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/global/homes/u/uthpala/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/global/homes/u/uthpala/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/global/homes/u/uthpala/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/global/homes/u/uthpala/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


py2(){
conda deactivate
conda activate py2
# module unload anaconda3/2020.11
# module load anaconda2/2019.10
}
py3(){
conda deactivate
conda activate py3
# module unload anaconda2/2019.10
# module load anaconda3/2020.11
}
#default
py3

# extract, mkcdr and archive creattion were taken from
# https://gist.github.com/JakubTesarek/8840983
# Easy extract
extract () {
if [ -f $1 ] ; then
case $1 in
*.tar.bz2)   tar xvjf $1    ;;
*.tar.gz)    tar xvzf $1    ;;
*.bz2)       bunzip2 $1     ;;
*.rar)       rar x $1       ;;
*.gz)        gunzip $1      ;;
*.tar)       tar xvf $1     ;;
*.tbz2)      tar xvjf $1    ;;
*.tgz)       tar xvzf $1    ;;
*.zip)       unzip $1       ;;
*.Z)         uncompress $1  ;;
*.7z)        7z x $1        ;;
*)           echo "don't know how to extract '$1'..." ;;
esac
else
echo "'$1' is not a valid file!"
fi
}
# Creates directory then moves into it
mkcdr() {
  mkdir -p -v $1
cd $1
}
# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# Clean VASP files in current directoy and subdirectories.
# For only current directory use cleanvasp.sh
cleanvaspall(){
 find . \( \
     -name "CHGCAR*" -o \
     -name "OUTCAR*" -o \
     -name "CHG" -o \
     -name "DOSCAR" -o \
     -name "EIGENVAL" -o \
     -name "ENERGY" -o \
     -name "IBZKPT" -o \
     -name "OSZICAR*" -o \
     -name "PCDAT" -o \
     -name "REPORT" -o \
     -name "TIMEINFO" -o \
     -name "WAVECAR" -o \
     -name "XDATCAR" -o \
     -name "wannier90.wout" -o \
     -name "wannier90.amn" -o \
     -name "wannier90.mmn" -o \
     -name "wannier90.eig" -o \
     -name "wannier90.chk" -o \
     -name "wannier90.node*" -o \
     -name "PROCAR" -o \
     -name "*.o[0-9]*" -o \
     -name "vasprun.xml" -o \
     -name "relax.dat" -o \
     -name "CONTCAR*" \
 \) -type f $1
}

# Check if VASP relaxation is obtained for batch jobs when relaxed with
# Convergence.py and relax.dat is created.
relaxed (){
 if [ "$*" == "" ]; then
     arg="^[0-9]+$"
 else
     arg=$1
 fi

 rm -f unrelaxed_list.dat
 folder_list=$(ls | grep -E $arg)
 for i in $folder_list;
     do if [ -f $i/relax.dat ] ; then
            echo $i
        else
            printf "$i\t" >> unrelaxed_list.dat
        fi
     done
}

# perlmutter
#makejob(){
# nodes=${1:-1}
# ppn=${2:-128}
# jobname=${3:-jobname}

#echo "\
##!/bin/bash
##SBATCH --job-name=$jobname
##SBATCH -N $nodes
##SBATCH --ntasks-per-node=$ppn
##SBATCH -t 48:00:00
###SBATCH --mem=10GB
###SBATCH -p RM-shared

#set -x
#source ~/.bashrc
#ulimit -s unlimited

#cd \$WORK_DIR/
#" > jobscript.sh
#}


#------------------------------------------- PATHS -------------------------------------------

# slate
# export LD_LIBRARY_PATH="~/local/slate-2021.05.02_default_gpu/build/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/global/u2/u/uthpala/local/slate-2021.05.02_gpu/build/opt/slate/lib/:$LD_LIBRARY_PATH"

# libraries
#export LD_LIBRARY_PATH="~/lib/BLAS-3.10.0/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/fftw-3.3.10/build/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/lapack-3.10.1/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/libxc-5.2.3/build/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/scalapack-2.2.0/:$LD_LIBRARY_PATH"

# FHI-aims
export PATH="~/local/FHIaims/bin/:$PATH"
export PATH="/global/homes/u/uthpala/local/Yi/FHIaims/bin/:$PATH"

# MatSciScripts
export PATH="~/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"
