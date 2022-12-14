# -*- shell-script -*-
# TACC startup script: ~/.bashrc version 2.1 -- 12/17/2013


# This file is NOT automatically sourced for login shells.
# Your ~/.profile can and should "source" this file.

# Note neither ~/.profile nor ~/.bashrc are sourced automatically by
# bash scripts. However, a script inherits the environment variables
# from its parent shell.  Both of these facts are standard bash
# behavior.
#
# In a parallel mpi job, this file (~/.bashrc) is sourced on every 
# node so it is important that actions here not tax the file system.
# Each nodes' environment during an MPI job has ENVIRONMENT set to
# "BATCH" and the prompt variable PS1 empty.

#################################################################
# Optional Startup Script tracking. Normally DBG_ECHO does nothing
if [ -n "$SHELL_STARTUP_DEBUG" ]; then
  DBG_ECHO "${DBG_INDENT}~/.bashrc{"
fi

############
# SECTION 1
#
# There are three independent and safe ways to modify the standard
# module setup. Below are three ways from the simplest to hardest.
#   a) Use "module save"  (see "module help" for details).
#   b) Place module commands in ~/.modules
#   c) Place module commands in this file inside the if block below.
#
# Note that you should only do one of the above.  You do not want
# to override the inherited module environment by having module
# commands outside of the if block[3].

if [ -z "$__BASHRC_SOURCED__" -a "$ENVIRONMENT" != BATCH ]; then
  export __BASHRC_SOURCED__=1

  ##################################################################
  # **** PLACE MODULE COMMANDS HERE and ONLY HERE.              ****
  ##################################################################

  # module load git

fi

############
# SECTION 2
#
# Please set or modify any environment variables inside the if block
# below.  For example, modifying PATH or other path like variables
# (e.g LD_LIBRARY_PATH), the guard variable (__PERSONAL_PATH___) 
# prevents your PATH from having duplicate directories on sub-shells.

if [ -z "$__PERSONAL_PATH__" ]; then
  export __PERSONAL_PATH__=1

  ###################################################################
  # **** PLACE Environment Variables including PATH here.        ****
  ###################################################################

  # export PATH=$HOME/bin:$PATH

fi

########################
# SECTION 3
#
# Controling the prompt: Suppose you want stampede1(14)$  instead of 
# login1.stampede(14)$ 
# 
#if [ -n "$PS1" ]; then
#   myhost=$(hostname -f)              # get the full hostname
#   myhost=${myhost%.tacc.utexas.edu}  # remove .tacc.utexas.edu
#   first=${myhost%%.*}                # get the 1st name (e.g. login1)
#   SYSHOST=${myhost#*.}               # get the 2nd name (e.g. stampede)
#   first5=$(expr substr $first 1 5)   # get first 5 character from $first
#   if [ "$first5" = "login" ]; then
#     num=$(expr $first : '[^0-9]*\([0-9]*\)') # get the number
#     HOST=${SYSHOST}$num                      # HOST -> stampede1
#   else
#     # first is not login1 so take first letter of system name
#     L=$(expr substr $SYSHOST 1 1 | tr '[:lower:]' '[:upper:]')
#
#     #  If host is c521-101.stampeded then
#     HOST=$L$first      # HOST  -> Sc521-101 
#   fi
#   PS1='$HOST(\#)\$ '   # Prompt either stampede1(14)$ or Sc521-101(14)$ 
#fi
#####################################################################
# **** Place any else below.                                     ****
#####################################################################

# alias m="more"
# alias bls='/bin/ls'   # handy alias for listing a large directory.

##########
# Umask
#
# If you are in a group that wishes to share files you can use 
# "umask". to make your files be group readable.  Placing umask here 
# is the only reliable place for bash and will insure that it is set 
# in all types of bash shells.

# umask 022

###################################
# Optional Startup Script tracking 

if [ -n "$SHELL_STARTUP_DEBUG" ]; then
  DBG_ECHO "${DBG_INDENT}}"
fi


#------------------------------------------------------------------------------------------------------

#.bashrc for stampede2 (stampede2.tacc.xsede.org)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
if [[ -t 0 && $- = *i* ]]
then
stty -ixon
fi

# tmux
export TMUX_DEVICE_NAME=stampede2
if command -v ~/bin/tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    ~/bin/tmux new-session -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME 
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
. /etc/bashrc
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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home1/05979/uthpala/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home1/05979/uthpala/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home1/05979/uthpala/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home1/05979/uthpala/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

#------------------------------------------- ALIASES -------------------------------------------

#alias q="squeue -u uthpala"
alias q='squeue -u uthpala --format="%.18i %.9P %30j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias scratch="cd /scratch/05979/uthpala"
alias interact="idev -p normal -N 1 --tasks-per-node 16 -m 240 -A TG-DMR140031"
alias standby="idev -p development -N 1 --tasks-per-node 16 -m 120 -A TG-DMR140031"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from stampede2" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias detach="tmux detach-client -a"

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/stampede2/jobscript.sh ."
alias makeabinit="cp ~/MatSciScripts/{abinit.files,abinit.in} ."

#------------------------------------------- MODULES -------------------------------------------

# Purge
module purge

# compilers
module load intel/18.0.2
#module load gcc/7.1.0
#module load gcc/7.3.0
#module load gcc/9.1.0

# sourcing intel compilers
source /opt/intel/compilers_and_libraries_2018.2.199/linux/bin/compilervars.sh intel64
source /opt/intel/compilers_and_libraries_2018.2.199/linux/mkl/bin/mklvars.sh intel64


# libraries
module load gsl/2.6
# module load netcdf/4.6.2


#------------------------------------------- FUNCTIONS -------------------------------------------

checkjob(){
    scontrol show job=$1
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
# default
py3

#------------------------------------------- PATHS -------------------------------------------

# tmux
export PATH="~/bin/:$PATH"

# MatSciScripts
export PATH="~/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# wannier90
export PATH="~/local/wannier90/wannier90-1.2/:$PATH"
export WANNIER_DIR="~/local/wannier90/wannier90-1.2/"
export PATH="~/local/wannier90/wannier90-3.1.0/:$PATH"

# vasp
export PATH="~/local/VASP/vasp_dmft/:$PATH"
export PATH="~/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="~/local/VASP/vasp.5.4.4/bin/:$PATH"

# Abinit
export PATH="/home1/05979/uthpala/local/abinit/abinit-8.10.3/build/bin/:$PATH"
export PAW_PBE="/home1/05979/uthpala/local/abinit/pseudo-dojo/paw_pbe_standard/"
export PAW_LDA="/home1/05979/uthpala/local/abinit/pseudo-dojo/paw_pw_standard/"


# DMFT
#export PATH="/home/uthpala/projects/DFTDMFT/bin/:$PATH"
#export WIEN_DMFT_ROOT="/home/uthpala/projects/DFTDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/projects/DFTDMFT/bin/:$PYTHONPATH"
#DMFT post-processing
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/src_files/ksum/:$PATH"
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/bands/:$PATH"

# DMFTwDFT
export PATH="~/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="~/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="~/projects/DMFTwDFT/bin/"
export PATH="~/projects/DMFTwDFT/scripts/:$PATH"

# # DMFTwDFT_eb
# export PATH="~/projects/DMFTwDFT_eb/bin/:$PATH"
# export PYTHONPATH="~/projects/DMFTwDFT_eb/bin/:$PYTHONPATH"
# export DMFT_ROOT="~/projects/DMFTwDFT_eb/bin/"
# export PATH="~/projects/DMFTwDFT_eb/scripts/:$PATH"


# Dispy
export PATH="/home1/05979/uthpala/local/DiSPy/scripts/:$PATH"

# NEBgen
export PATH="/home1/05979/uthpala/local/NEBgen/:$PATH"

#VTST
export PATH="/home1/05979/uthpala/local/VTST/vtstscripts-957/:$PATH"


# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"

# GSL LIBRARY
export LD_LIBRARY_PATH="/home1/05979/uthpala/local/gsl-2.6/bin/lib/:$LD_LIBRARY_PATH"






