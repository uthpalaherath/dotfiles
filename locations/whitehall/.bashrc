# .bashrc for whitehall
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi

# tmux
export TMUX_DEVICE_NAME=whitehall
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    tmux attach -t whitehall || tmux new -s whitehall
    # tmux
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Memory
ulimit -s unlimited

# intel stuff
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

# source .bash_prompt for colors
source ~/.bash_prompt

#------------------------------------------- PATHS -------------------------------------------

# vasp
export PATH="/home/ukh0001/local/VASP/vasp.5.4.4/bin/:$PATH"
export PATH="/home/ukh0001/local/VASP/vasp_dmft/:$PATH"

# wannier90
export PATH="/home/ukh0001/local/wannier90/wannier90-1.2/:$PATH"
export WANNIER_DIR="/home/ukh0001/local/wannier90/wannier90-1.2/"

# md project
export PATH="/home/ukh0001/projects/moleculardynamics/src/:$PATH"

# siesta
export PATH="/home/ukh0001/local/siesta/siesta-4.1-b3/Obj/:$PATH"
export PATH="/home/ukh0001/local/siesta/lowdin/Obj:$PATH"

# DMFT
#export WIEN_DMFT_ROOT="/home/ukh0001/projects/DMFT/vaspDMFT/bin/"
#export PYTHONPATH="/home/ukh0001/projects/DMFT/vaspDMFT/bin/:$PYTHONPATH"
#export DMFT_ROOT="/home/ukh0001/projects/DMFT/vaspDMFT/bin/"
#export PATH="/home/ukh0001/projects/DMFT/vaspDMFT/post_processing/bands/:$PATH"
#export PATH="/home/ukh0001/projects/DMFT/vaspDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/ukh0001/local/VASP/vasp_dmft/:$PATH"

# DMFTwDFT
export PATH="/home/ukh0001/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/ukh0001/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/ukh0001/projects/DMFTwDFT/bin/"
export PATH="/home/ukh0001/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"

# dotfiles
export PATH="/home/ukh0001/dotfiles/:$PATH"

# usr/local/lib
export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"
export PATH="/usr/local/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/lib64/:$LD_LIBRARY_PATH"

# MPI
#export I_MPI_CC="mpiicc"
#export MPICC="mpiicc"
#export MPICH_CC="mpiicc"

#R libraries
export PATH="/usr/lib64/R/library/:$PATH"
export R_LIBS="/usr/lib64/R/library/:$R_LIBS"

# globusconnectpersonal
export PATH="/home/ukh0001/local/globusconnectpersonal/:$PATH"

# vim
# export PATH="/home/ukh0001/local/vim/bin/:$PATH"

# anaconda
export PATH="/home/ukh0001/anaconda2/bin/:$PATH"
export PATH="/home/ukh0001/anaconda3/bin/:$PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias desktop="ssh -XC uthpala@157.182.27.178"
alias desktop2="ssh -XC uthpala@157.182.28.27"
alias whitehall2="ssh -XC ukh0001@157.182.3.75"
alias whitehall3="ssh -XC ukh0001@157.182.3.77"
alias whitehall4="ssh -XC ukh0001@157.182.3.81"
alias whitehall5="ssh -XC ukh0001@157.182.3.82"
alias cleantmux='tmux kill-session -a'

#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
    for arg
    do tmux kill-session -t "whitehall $arg"
    done
}
