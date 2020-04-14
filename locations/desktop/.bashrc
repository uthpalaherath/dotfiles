# .bashrc for desktop (157.182.27.178)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# set stty off
if [[ -t 0 && $- = *i* ]]
then
stty -ixon
fi

# tmux
export TMUX_DEVICE_NAME=desktop
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
tmux attach -t desktop || tmux new -s desktop
#tmux
fi

#Intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

# Memory
ulimit -s unlimited

# Source ~/.bash_prompt for colors
source ~/.bash_prompt

#------------------------------------------- ALIASES -------------------------------------------

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias spruce='ssh -XYC ukh0001@spruce.hpc.wvu.edu'
alias bridges='ssh -XYC uthpala@bridges.psc.xsede.org'
alias stampede='ssh -XYC uthpala@stampede2.tacc.xsede.org'
alias whitehall='ssh -XYC ukh0001@157.182.3.76'
alias thorny="ssh -XYC ukh0001@thorny.hpc.wvu.edu"
alias spruce2="ssh -XYC ukh0001@ssh.wvu.edu"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from desktop" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

#------------------------------------------- PATHS -------------------------------------------

# SET MPI
export  I_MPI_SHM_LMT=shm

# VESTA
export PATH="/home/VESTA:$PATH"

# vasp
export PATH="/home/uthpala/VASP/vasp.5.4.4/bin/:$PATH"
export PATH="/home/uthpala/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="/home/uthpala/VASP/vasp_dmft/:$PATH"

# wannier90
export PATH="/home/uthpala/lib/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/home/uthpala/lib/wannier90/wannier90-1.2/"

# DMFT project
#export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PYTHONPATH"
#DMFT post processing
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/bands/:$PATH"

# DMFTwDFT bin
export PATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT/bin/"

# LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/opt/intel/mkl/lib/intel64/:/home/uthpala/lib/gsl/lib/:$LD_LIBRARY_PATH"

# anaconda
export PATH="/home/uthpala/anaconda2/bin:$PATH"
export PATH="/home/uthpala/anaconda3/bin:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# siesta
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Bands/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Contrib/APostnikov/:$PATH"
export PATH="/home/uthpala/siesta/siestal/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siestaw/Obj/:$PATH"

# elk
export PATH="/home/uthpala/elk-5.2.14/src/:$PATH"
export PATH="/home/uthpala/elk-5.2.14/src/spacegroup/:$PATH"

# cc
export CXX="mpiicpc"
export CC="mpiicc"
export FC="mpiifort"

# sod
export PATH="/home/uthpala/sod/bin/:$PATH"

# supercell
export PATH="/home/uthpala/supercell-linux/:$PATH"

# globus
export PATH="/home/uthpala/globus/:$PATH"

# jmol
export PATH="/home/uthpala/jmol/:$PATH"

# julia
export PATH="/home/uthpala/julia/bin/:$PATH"

# hdf5
export HDF5_TOOLS_DIR="/home/uthpala/lib/hdf5-1.10.4/tools/"
export HDF5_ROOT="/home/uthpala/lib/hdf5-1.10.4/hdf5/bin/"
export HDF5_LIBRARIES="/home/uthpala/lib/hdf5-1.10.4/hdf5/lib/"
export HD5F_INCLUDE_DIRS="/home/uthpala/lib/hdf5-1.10.4/hdf5/include/"

# MatSciScripts
export PATH="/home/uthpala/MatSciScripts/:$PATH"
