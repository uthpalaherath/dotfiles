# .bashrc for timewarp (timewarp.egr.duke.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# module purge

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
#export PATH="/jet/home/uthpala/local/bin/:$PATH"
export TMUX_DEVICE_NAME=timewarp
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
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
alias cat='pygmentize -g'

export PATH=./:/globalspace/CompMatSci_2021/bin:/globalspace/CompMatSci_2021/utilities:/home/vwb3/.local/bin:/usr/local/bin:~/bin:$PATH
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
#export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0
export I_MPI_PMI_LIBRARY=/usr/lib/x86_64-linux-gnu/libpmi.so.0
# export SLURM_CPU_BIND="cores"
# unset I_MPI_PMI_LIBRARY
# export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=0
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LIBRARY_PATH

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u ukh --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact="salloc --nodes 1 --ntasks-per-node=20 --qos interactive --time 04:00:00"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from timewarp" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/timewarp/jobscript.sh ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"

#------------------------------------------- MODULES -------------------------------------------

# module load cmake-3.14.4
# module load git-2.37.3

intel(){
    #module unload intel-compilers-2018.4
    #module load gcc-7.5
    # module load compiler/latest
    # module load mkl/latest
    # module load mpi/latest
    # source /Space/globalspace/intel-2023.0/setvars.sh > /dev/null
    # export LD_LIBRARY_PATH="/opt/intel/lib/intel64/:$LD_LIBRARY_PATH"

    # 2024
    source /home/ukh/intel/oneapi/setvars.sh > /dev/null

    # compilers
    export CC="mpiicc"
    export CXX="mpiicpc"
    export FC="mpiifort"
    export MPICC="mpiicc"
    export MPIFC="mpiifort"
}

intel18(){
    module load intel-compilers-2018.4
    source /opt/intel/bin/compilervars.sh intel64
}

gnu(){
    # module load gcc-7.5
    # module load gcc-8.2
    module load gcc-12.2.0
    export PATH="/home/ukh/lib/openmpi-4.1.5/build/bin/:$PATH$"
    export LD_LIBRARY_PATH="/home/ukh/lib/openmpi-4.1.5/build/lib/:$LD_LIBRARY_PATH"

    # export PATH="/home/ukh/lib/mpich-3.2.1/build/bin/:$PATH"
    # export LD_LIBRARY_PATH="/home/ukh/lib/mpich-3.2.1/build/lib/:$LD_LIBRARY_PATH"
    # export MPI_ROOT="/home/ukh/lib/mpich-3.2.1/build/"

    # compilers
    export CC="mpicc"
    export CXX="mpicxx"
    export FC="mpif90"
    export MPICC="mpicc"
    export MPIFC="mpif90"

}

# default
intel

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ukh/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ukh/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ukh/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ukh/miniconda3/bin:$PATH"
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

# timewarp
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

jobinfo(){
    scontrol show jobid -dd $1
}

#------------------------------------------- PATHS -------------------------------------------

# tmux
export PATH="/home/ukh/local/bin/:$PATH"

# FHI-aims
export PATH="/home/ukh/local/FHIaims/bin/:$PATH"
export PATH="/home/ukh/local/FHIaims/utilities/:$PATH"

# MatSciScripts
export PATH="/home/ukh/MatSciScripts/:$PATH"

# dotfiles
export PATH="/home/ukh/dotfiles/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"

# ctags
export PATH="/home/ukh/local/ctags-5.8/build/bin/:$PATH"

# vim
export PATH="/home/ukh/local/vim/build/bin/:$PATH"

# curl
# export PATH="/home/ukh/local/curl-7.85.0/build/bin/:$PATH"
# export LD_LIBRARY_PATH="/home/ukh/local/curl-7.85.0/build/lib/:$LD_LIBRARY_PATH"
# export PKG_CONFIG_PATH="/home/ukh/local/curl-7.85.0/build/pkgconfig:$PKG_CONFIG_PATH"
# export MANPATH="/home/ukh/local/curl-7.85.0/build/share/man:$MANPATH"

# python library
# export PATH="/home/ukh/local/Python-3.9.9/build/bin:$PATH"
# export LD_LIBRARY_PATH="/home/ukh/local/Python-3.9.9/build/lib:$LD_LIBRARY_PATH"

# go
export PATH="/home/ukh/local/go/bin/:$PATH"

# clang
export PATH="/home/ukh/local/llvm-project/build/bin:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/llvm-project/build/lib:$LD_LIBRARY_PATH"

# node
export PATH="/home/ukh/local/node-v16.10.0-linux-x64/bin/:$PATH"

# libtool
export PATH="/home/ukh/local/libtool-2.4.6/build/bin/:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/libtool-2.4.6/build/lib:$LD_LIBRARY_PATH"

# nvim
export PATH="/home/ukh/local/neovim/bin/:$PATH"

# abacus
export PATH="/home/ukh/local/abacus/build/bin/:$PATH"

# globus
export PATH="/home/ukh/local/globusconnectpersonal-3.2.0/:$PATH"

# scalapack
export LD_LIBRARY_PATH="/home/ukh/lib/scalapack-2.2.0/:$LD_LIBRARY_PATH"
