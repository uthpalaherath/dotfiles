# .bashrc for desktop2 (157.182.28.27)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# tmux
export TMUX_DEVICE_NAME=desktop2
# if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
#  # (cd $PWD; tmux attach-session -t desktop -c $PWD  ) || (cd $PWD; tmux new -s desktop -c $PWD  )
#  exec tmux
# fi

#sourcing intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

# Memory
ulimit -s unlimited

# Source for colorful terminal
source ~/.bash_prompt

#------------------------------------------- ALIASES -------------------------------------------

alias spruce='ssh -X ukh0001@spruce.hpc.wvu.edu'
alias bridges='ssh -XYC uthpala@bridges.psc.xsede.org'
alias stampede='ssh -XYC uthpala@stampede2.tacc.xsede.org'
alias whitehall="ssh -XC ukh0001@157.182.3.76"
alias cleantmux="tmux kill-session -a"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from desktop2" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
    for arg
    do tmux kill-session -t "desktop2 $arg"
    done
}

#------------------------------------------- PATHS -------------------------------------------

# set MPI
export I_MPI_SHM_LMT=shm

# vasp
export PATH="/home/uthpala/VASP/vasp.5.4.4/bin/:$PATH"

# anaconda
export PATH="/home/uthpala/anaconda2/bin/:$PATH"
export PATH="/home/uthpala/anaconda3/bin/:$PATH"

# Library path
export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"

# scripts
export PATH="~/dotfiles/:$PATH"

# DMFT
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PYTHONPATH"
#export DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/VASP/vasp_dmft/bin/:$PATH"
#export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/bands/:$PATH"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/ancont_PM/:$PATH"

# DMFTwDFT
export PATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/"
export PATH="/home/uthpala/VASP/vasp.5.4.4_dmft/bin/:$PATH"

# wannier90
export PATH="/home/uthpala/wannier90/wannier90-1.2/:$PATH"
#export PATH="/home/uthpala/wannier90/wannier90-3.0.0/:$PATH"

# Vesta
export PATH="/home/uthpala/VESTA/:$PATH"

# globus
export PATH="/home/uthpala/globusconnectpersonal/:$PATH"

# siesta
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-lowdin/Obj/:$PATH"

# NETCDF
export NETCDF_ROOT="/opt/netcdf/"
export LD_LIBRARY_PATH="/opt/netcdf/lib/:$LD_LIBRARY_PATH"

# EDMFT
#export WIEN_DMFT_ROOT=$HOME/EDMFT/bin
export PYTHONPATH=$PYTHONPATH:$WIEN_DMFT_ROOT
#export WIENROOT=$HOME/wien2k
export SCRATCH="."
export EDITOR="vim"
export PATH=$WIENROOT:$WIEN_DMFT_ROOT:$PATH

# elk
export PATH="/home/uthpala/elk/elk-6.3.2/src/:$PATH"
export PATH="/home/uthpala/elk/elk-6.3.2/src/spacegroup/:$PATH"

# go
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"