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
if command -v tmux &> /dev/null && [ -t 0  ] && [[ -z $TMUX  ]] && [[ $- = *i*  ]]; then
    #tmux attach -t desktop2 || tmux new -s desktop2
    tmux new-session -t desktop2 || tmux new -s desktop2
    #exec tmux
fi

# Memory
ulimit -s unlimited

# Source for colorful terminal
source ~/.bash_prompt

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'


#------------------------------------------- ALIASES -------------------------------------------

alias desktop="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY uthpala@157.182.27.178'"
alias spruce='ssh -XY ukh0001@spruce.hpc.wvu.edu'
alias whitehall="ssh -XY ukh0001@157.182.3.76"
alias thorny="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@tf.hpc.wvu.edu'"
alias bridges="ssh -tXY  uthpala@bridges.psc.xsede.org 'ssh -XY br005.pvt.bridges.psc.edu'"
alias stampede2="ssh -XY  uthpala@login1.stampede2.tacc.utexas.edu"

alias cleantmux="tmux kill-session -a"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from desktop2" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias detach="tmux detach-client -a"

alias makeINCAR="cp ~/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/Dropbox/git/MatSciScripts/KPOINTS ."
alias makeabinit="cp ~/Dropbox/git/MatSciScripts/{abinit.in,abinit.files} ."

alias display_off="sudo vbetool dpms off"
alias display_on="sudo vbetool dpms on"

#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
    for arg
    do tmux kill-session -t "desktop2 $arg"
    done
}

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


#------------------------------------------- PATHS -------------------------------------------

# set MPI
# export I_MPI_SHM_LMT=shm

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# vasp
export PATH="/home/uthpala/VASP/vasp.5.4.4/bin/:$PATH"

# abinit
export PAW_PBE="/home/uthpala/abinit/pseudo-dojo/paw_pbe_standard"
export PAW_LDA="/home/uthpala/abinit/pseudo-dojo/paw_pw_standard"
export NC_PBEsol="/home/uthpala/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8"

# Library path
 export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"

# # /usr/local/bin/
# export PATH="/usr/local/bin/:$PATH"


# Anaconda
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/uthpala/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/uthpala/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/uthpala/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/uthpala/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# export PATH="/home/uthpala/anaconda3/bin/:$PATH"
py2(){
    conda activate py2
}
py3(){
    conda activate py3
}
#default
py3

# scripts
export PATH="~/dotfiles/:$PATH"

# DMFT
# export PATH="/home/uthpala/Dropbox/git/DMFT_old/bin/:$PATH"
# export PYTHONPATH="/home/uthpala/Dropbox/git/DMFT_old/bin/:$PYTHONPATH"
# export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFT_old/bin/"
# export PATH="/home/uthpala/VASP/vasp_dmft/bin/:$PATH"
# export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/git/DMFT_old/bin/"
# # DMFT post-processing
# export PATH="/home/uthpala/Dropbox/git/DMFT_old/post_processing/bands/:$PATH"
# export PATH="/home/uthpala/Dropbox/git/DMFT_old/post_processing/ancont_PM/:$PATH"

# DMFTwDFT3
# export PATH="/home/uthpala/Dropbox/git/DMFTwDFT3/bin/:$PATH"
# export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT3/bin/:$PYTHONPATH"
# export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT3/bin/"
# export PATH="/home/uthpala/VASP/vasp.5.4.4_dmft/bin/:$PATH"

# DMFTwDFT
export PATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT/bin/"
export PATH="/home/uthpala/Dropbox/git/DMFTwDFT/scripts/:$PATH"

# DMFTwDFT_eb
# export PATH="/home/uthpala/Dropbox/git/DMFTwDFT_eb/bin/:$PATH"
# export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT_eb/bin/:$PYTHONPATH"
# export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT_eb/bin/"
# export PATH="/home/uthpala/Dropbox/git/DMFTwDFT_eb/scripts/:$PATH"

# DMFTwDFT_tetra
# export PATH="/home/uthpala/Dropbox/git/DMFTwDFT_tetra/bin/:$PATH"
# export PYTHONPATH="/home/uthpala/Dropbox/git/DMFTwDFT_tetra/bin/:$PYTHONPATH"
# export DMFT_ROOT="/home/uthpala/Dropbox/git/DMFTwDFT_tetra/bin/"
# export PATH="/home/uthpala/Dropbox/git/DMFTwDFT_tetra/scripts/:$PATH"


# Vesta
export PATH="/home/uthpala/VESTA/:$PATH"

# globus
export PATH="/home/uthpala/globusconnectpersonal/:$PATH"

# siesta
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/COOP/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Bands/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft-original/Obj/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft/Util/COOP/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft/Util/Bands/:$PATH"

# hdf5
export LD_LIBRARY_PATH="/home/uthpala/hdf5-1.10.5/hdf5/lib/:$LD_LIBRARY_PATH"

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
# export PATH="/home/uthpala/elk/elk-6.3.2/src/:$PATH"
# export PATH="/home/uthpala/elk/elk-6.3.2/src/spacegroup/:$PATH"
export PATH="/home/uthpala/elk/elk-7.0.12/src/:$PATH"
export PATH="/home/uthpala/elk/elk-7.0.12/src/spacegroup/:$PATH"


# wannier90
#export PATH="/home/uthpala/wannier90/wannier90-1.2/:$PATH"
export PATH="/home/uthpala/wannier90/wannier90-3.1.0/:$PATH"


# go
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

# MatSciScripts
export PATH="/home/uthpala/Dropbox/git/MatSciScripts/:$PATH"

# Quantum Espresso
export PATH="/home/uthpala/qe-6.5/bin/:$PATH"

# Pandoc
export PATH="/home/uthpala/Dropbox/git/pandoc-templates/scripts/:$PATH"

# DFTB+
export PATH="/home/uthpala/DFTB+/dftb+/bin/:$PATH"

#Intel compilers
source /opt/intel/oneapi/setvars.sh > /dev/null
#export I_MPI_ADJUST_REDUCE=3
# export LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/linux/lib/:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64/:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="/opt/intel/oneapi/mkl/latest/lib/intel64/:$LD_LIBRARY_PATH"

# # compilers
# export CC="mpicc"
# export CXX="mpicxx"
# export FC="mpif90"
# export F77="mpif90"

# export I_MPI_CC="icc"
# export I_MPI_CXX="icpc"
# export I_MPI_FC="ifort"
# export I_MPI_F90="ifort"
# export I_MPI_F77="ifort"

#OpenMPI
# export LD_LIBRARY_PATH="/opt/openmpi/lib/:$LD_LIBRARY_PATH"
# export PATH="/opt/openmpi/bin/:$PATH"

#------------------------------------------------------------------------
# this is for XCRYSDEN 1.5.60; added by XCRYSDEN installation on
# Tue Apr 20 17:20:59 EDT 2021
#------------------------------------------------------------------------
XCRYSDEN_TOPDIR=/home/uthpala/xcrysden-1.5.60-bin-semishared
XCRYSDEN_SCRATCH=/home/uthpala/xcrys_tmp
export XCRYSDEN_TOPDIR XCRYSDEN_SCRATCH
PATH="$XCRYSDEN_TOPDIR:$PATH:$XCRYSDEN_TOPDIR/scripts:$XCRYSDEN_TOPDIR/util"
