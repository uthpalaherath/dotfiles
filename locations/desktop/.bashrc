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
source /home/uthpala/intel/oneapi/setvars.sh > /dev/null

# Memory
ulimit -s unlimited

# Source ~/.bash_prompt for colors
source ~/.bash_prompt
source ~/.aliases

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/uthpala/intel/oneapi/intelpython/latest/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/uthpala/intel/oneapi/intelpython/latest/etc/profile.d/conda.sh" ]; then
        . "/home/uthpala/intel/oneapi/intelpython/latest/etc/profile.d/conda.sh"
    else
        export PATH="/home/uthpala/intel/oneapi/intelpython/latest/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# compilers
export OMPI_FC=gfortran-11
export OMPI_CC=gcc-11
export OMPI_CXX=g++-11
export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"
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
alias mount_gd="google-drive-ocamlfuse GoogleDrive"

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
export PATH="/home/uthpala/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/home/uthpala/wannier90/wannier90-1.2/"

# DMFT project
#export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PYTHONPATH"
#DMFT post processing
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/bands/:$PATH"

# DMFTwDFT
# export PATH="/home/uthpala/DMFTwDFT/bin/:$PATH"
# export PATH="/home/uthpala/DMFTwDFT/scripts/:$PATH"
# export PYTHONPATH="/home/uthpala/DMFTwDFT/bin/:$PYTHONPATH"
# export DMFT_ROOT="/home/uthpala/DMFTwDFT/bin/"
export PATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PATH="/home/uthpala/Dropbox/git/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT/bin/"

# LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/opt/intel/mkl/lib/intel64/:/home/uthpala/lib/gsl/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/home/uthpala/lib/hdf5-1.12.1/hdf5/lib/:$LD_LIBRARY_PATH$"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# siesta
export PATH="/home/uthpala/siesta/siesta-4.1.5/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1.5/Util/Bands/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1.5/Util/Contrib/APostnikov/:$PATH"
export PATH="/home/uthpala/siesta/siestal/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siestaw/Obj/:$PATH"

# elk
export PATH="/home/uthpala/elk-5.2.14/src/:$PATH"
export PATH="/home/uthpala/elk-5.2.14/src/spacegroup/:$PATH"

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
export PATH="/home/uthpala/Dropbox/git/MatSciScripts/:$PATH"

# VTST
export PATH="/home/uthpala/VTST/vtstscripts-957/:$PATH"

# START-QMCPACK-RELATED
# QMCPACK and NEXUS
export PATH=$HOME/apps/qmcpack/bin:$PATH
export PATH=$HOME/apps/qmcpack/qmcpack/nexus/bin:$PATH
export PYTHONPATH=$HOME/apps/qmcpack/qmcpack/nexus/lib:$PYTHONPATH
export PYTHONPATH=$HOME/apps/qmcpack/qmcpack/utils/afqmctools:$PYTHONPATH
# QE
#export PATH=$HOME/apps/qe-6.8/bin:$PATH
export PATH=$HOME/qe/qe-7.0/bin:$PATH
# PySCF
export PYTHONPATH=$HOME/apps/pyscf/pyscf:$PYTHONPATH
export PYTHONPATH=$HOME/apps/qmcpack/qmcpack/src/QMCTools:$PYTHONPATH
export LD_LIBRARY_PATH=$HOME/apps/pyscf/pyscf/opt/lib:$LD_LIBRARY_PATH
# QP
if [ -e $HOME/apps/qp2/quantum_package.rc ]; then
source $HOME/apps/qp2/quantum_package.rc
fi
# DIRAC
export PATH=$HOME/apps/dirac/bin:$PATH
# VESTA
export PATH=$HOME/apps/vesta/VESTA-gtk3:$PATH
# END-QMCPACK-RELATED

# abinit
export PAWPBE="/home/uthpala/abinit/pseudo-dojo/paw_pbe_standard"
export PAWLDA="/home/uthpala/abinit/pseudo-dojo/paw_pw_standard"
export NC_PBEsol="/home/uthpala/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8"

# FHI-aims
export PATH="/home/uthpala/FHIaims/bin/:$PATH$"

#-------------------------------- FUNCTIONS -------------------------------------

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
*.tar.xz)    tar xf $1    ;;
*)           echo "don't know how to extract '$1'..." ;;
esac
else
echo "'$1' is not a valid file!"
fi
}
# Creates directory then moves into it
function mkcdr {
mkdir -p -v $1
cd $1
}
# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# python
py2(){
    conda deactivate
    conda activate py2
}

py3(){
    conda deactivate
    conda activate py3
}
#default
py3
