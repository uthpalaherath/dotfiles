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
~/bin/tmux attach -t stampede2 || ~/bin/tmux new -s stampede2 
#tmux
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
. /etc/bashrc
fi

# Memory
ulimit -s unlimited

# Source for colorful terminal
source ~/.bash_prompt

#------------------------------------------- ALIASES -------------------------------------------

alias q="squeue -u uthpala"
alias sac="sacct --format="JobID,JobName%30,State,User""
alias scratch="cd /scratch/05979/uthpala"
alias interact="idev -p normal -N 1 --tasks-per-node 16 -m 240 -A TG-DMR140031"
alias standby="idev -p development -N 1 --tasks-per-node 16 -m 120 -A TG-DMR140031"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from stampede2" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/stampede2/jobscript.sh ."


#------------------------------------------- MODULES -------------------------------------------

# compilers
module load intel/18.0.2

# python
#module load python2/2.7.15
module load python3/3.7.0

# libraries
module load gsl/2.3

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

# vasp
export PATH="~/local/VASP/vasp_dmft/:$PATH"
export PATH="~/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="~/local/VASP/vasp.5.4.4/bin/:$PATH"

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

# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"




