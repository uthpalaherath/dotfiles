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


#Intel compilers
source /home/uthpala/intel/oneapi/setvars.sh > /dev/null

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

### COMPILERS
# gnu compilers
gnu(){
    export OMPI_CC=gcc
    export OMPI_CXX=g++
    export OMPI_FC=gfortran
    export CC="mpicc"
    export CXX="mpicxx"
    export FC="mpif90"
    export F77="mpif90"
}

# intel compilers
intel(){
    export OMPI_CC=icc
    export OMPI_CXX=icpc
    export OMPI_FC=ifort
    export CC="mpiicc"
    export CXX="mpiicpc"
    export FC="mpiifort"
    export F77="mpiifort"
}
# default
intel

#OpenMPI
# export PATH="/home/uthpala/openmpi/openmpi-4.1.2/build/bin/:$PATH"
# export LD_LIBRARY_PATH="/home/uthpala/openmpi/openmpi-4.1.2/build/lib/:$LD_LIBRARY_PATH"
# export C_INCLUDE_PATH="/home/uthpala/openmpi/openmpi-4.1.2/build/include/:$C_INCLUDE_PATH"
# export CPLUS_INCLUDE_PATH="/home/uthpala/openmpi/openmpi-4.1.2/build/include/:$CPLUS_INCLUDE_PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias desktop="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY uthpala@157.182.27.178'"
alias spruce='ssh -XY ukh0001@spruce.hpc.wvu.edu'
alias whitehall="ssh -XY ukh0001@157.182.3.76"
alias thorny="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@tf.hpc.wvu.edu'"
alias bridges="ssh -tXY  uthpala@bridges.psc.xsede.org 'ssh -XY br005.pvt.bridges.psc.edu'"
alias stampede2="ssh -XY  uthpala@login1.stampede2.tacc.utexas.edu"
alias mount_gd="google-drive-ocamlfuse GoogleDrive"

alias cleantmux="tmux kill-session -a"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from desktop2" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"

alias makeINCAR="cp ~/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/Dropbox/git/MatSciScripts/KPOINTS ."
alias makeabinit="cp ~/Dropbox/git/MatSciScripts/{abinit.in,abinit.files} ."

alias display_off="sudo vbetool dpms off"
alias display_on="sudo vbetool dpms on"
# alias display_off="xset -display :0.0 dpms force off"
# alias display_on="xset -display :0.0 dpms force on"


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
#export PATH="/home/uthpala/VASP/vasp.6.2.1/bin/:$PATH"

# abinit
export PAWPBE="/home/uthpala/abinit/pseudo-dojo/paw_pbe_standard"
export PAWLDA="/home/uthpala/abinit/pseudo-dojo/paw_pw_standard"
export NC_PBEsol="/home/uthpala/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8"

# Library path
export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"

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
export PATH="/home/uthpala/globusconnectpersonal-3.1.6/:$PATH"

# siesta
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/COOP/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Bands/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft-original/Obj/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft/Util/COOP/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-dmft/Util/Bands/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1.5/Obj/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1.5/Util/COOP/:$PATH"
# export PATH="/home/uthpala/siesta/siesta-4.1.5/Util/Bands/:$PATH"

# glibc - DO NOT UNCOMMENT
# export LD_LIBRARY_PATH="/home/uthpala/glibc-2.34/build/lib/:$LD_LIBRARY_PATH"
# export PATH="/home/uthpala/glibc-2.34/build/bin/:$PATH"

# hdf5
export PATH="/home/uthpala/hdf5-1.12.1/hdf5/:$PATH"
export HDF5_ROOT="/home/uthpala/hdf5-1.12.1/hdf5/"
export LD_LIBRARY_PATH="/home/uthpala/hdf5-1.12.1/hdf5/lib/:$LD_LIBRARY_PATH"
export C_INCLUDE_PATH="/home/uthpala/hdf5-1.12.1/hdf5/include/:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="/home/uthpala/hdf5-1.12.1/hdf5/include/:$CPLUS_INCLUDE_PATH"
export HDF5_LIBRARIES="/home/uthpala/hdf5-1.12.1/hdf5/lib/"
export HDF5_HL_LIBRARIES="/home/uthpala/hdf5-1.12.1/hdf5/lib/"
export HD5F_INCLUDE_DIRS="/home/uthpala/hdf5-1.12.1/hdf5/include/"

# NETCDF
export NETCDF_ROOT="/home/uthpala/netcdf/netcdf-c-4.8.1/build/"
export LD_LIBRARY_PATH="/home/uthpala/netcdf/netcdf-c-4.8.1/build/lib/:$LD_LIBRARY_PATH"

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
export PATH="/home/uthpala/qe/qe-7.0/bin/:$PATH"

# Pandoc
export PATH="/home/uthpala/Dropbox/git/pandoc-templates/scripts/:$PATH"

# DFTB+
export PATH="/home/uthpala/DFTB+/dftb+/bin/:$PATH"


# START-QMCPACK-RELATED
# QMCPACK and NEXUS
export PATH=$HOME/apps/qmcpack/bin:$PATH
export PATH=$HOME/apps/qmcpack/qmcpack/nexus/bin:$PATH
export PYTHONPATH=$HOME/apps/qmcpack/qmcpack/nexus/lib:$PYTHONPATH
export PYTHONPATH=$HOME/apps/qmcpack/qmcpack/utils/afqmctools:$PYTHONPATH
# QE
export PATH=$HOME/apps/qe-6.8/bin:$PATH
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

# sod
export PATH="/home/uthpala/sod/bin/:$PATH"

# FHI-aims
export PATH="/home/uthpala/FHIaims/bin/:$PATH$"
