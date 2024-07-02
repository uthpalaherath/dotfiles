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
# Controling the prompt: Suppose you want frontera1(14)$  instead of
# login1.frontera(14)$
#
#if [ -n "$PS1" ]; then
#   myhost=$(hostname -f)              # get the full hostname
#   myhost=${myhost%.tacc.utexas.edu}  # remove .tacc.utexas.edu
#   first=${myhost%%.*}                # get the 1st name (e.g. login1)
#   SYSHOST=${myhost#*.}               # get the 2nd name (e.g. frontera)
#   first5=$(expr substr $first 1 5)   # get first 5 character from $first
#   if [ "$first5" = "login" ]; then
#     num=$(expr $first : '[^0-9]*\([0-9]*\)') # get the number
#     HOST=${SYSHOST}$num                      # HOST -> frontera1
#   else
#     # first is not login1 so take first letter of system name
#     L=$(expr substr $SYSHOST 1 1 | tr '[:lower:]' '[:upper:]')
#
#     #  If host is c521-101.fronterad then
#     HOST=$L$first      # HOST  -> Sc521-101
#   fi
#   PS1='$HOST(\#)\$ '   # Prompt either frontera1(14)$ or Sc521-101(14)$
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

# .bashrc for frontera (frontera.tacc.utexas.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Purge
# module purge

set stty off
if [[ -t 0 && $- = *i* ]];then
    stty -ixon
fi

# Source for colorful terminal
source ~/.bash_prompt

# tmux
export PATH="/home1/05979/uthpala/local/tmux/:$PATH"
export TMUX_DEVICE_NAME=frontera
if command -v tmux &> /dev/null && [ -t 0  ] && [[ -z $TMUX  ]] && [[ $- = *i*  ]]; then
    tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
. /etc/bashrc
fi

# Memory
ulimit -s unlimited

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

# compilers
intel(){

# intel
#module load intel/19.1.1
module load intel/23.1.0
# source /opt/intel/compilers_and_libraries_2020.4.304/linux/bin/compilervars.sh intel64
# export PATH="/opt/intel/compilers_and_libraries_2020.4.304/linux/mpi/intel64/bin/:$PATH"

export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
}

gnu(){
module load gcc/12.2.0
export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"
}
# default
intel

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

#ENV
NUM_CORES=$SLURM_NTASKS
WORK_DIR=$SLURM_SUBMIT_DIR

# CL
C_INCLUDE_PATH="/home1/apps/cuda/12.2/include/CL/:$C_INCLUDE_PATH"
CPLUS_INCLUDE_PATH="/home1/apps/cuda/12.2/include/CL/:$CPLUS_INCLUDE_PATH"

#FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_COMMAND='rg --files --type-not sql --smart-case --follow --hidden -g "!{node_modules,.git}" '
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || cat {} 2>/dev/null || tree -C {}'"
export FZF_CTRL_R_OPTS="
 --preview 'echo {}' --preview-window 'hidden'
 --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
 --color header:italic
 --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_OPTS="
 --walker-skip .git,node_modules,target
 --preview 'tree -C {}'"
export EDITOR="vim"

#------------------------------------------- ALIASES -------------------------------------------

#alias q="squeue -u uthpala"
alias q='squeue -u uthpala --format="%.18i %.9P %30j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias scratch="cd /scratch1/05979/uthpala"
alias interact="idev -p small -N 1 --tasks-per-node 56 -m 240 -A DMR23007"
alias interact_gpu="idev -p rtx-dev -N 1 --tasks-per-node 16 -m 120 -A DMR23007"
alias standby="idev -p development -N 1 --tasks-per-node 56 -m 120 -A DMR23007"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from frontera" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias detach="tmux detach-client -a"
alias globus="globusconnectpersonal -start -restrict-paths /home1/05979/uthpala,/scratch1/05979/uthpala &"

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/frontera/jobscript.sh ."
alias makegpujob="cp ~/dotfiles/locations/frontera/jobscript_gpu.sh ."
alias makeabinit="cp ~/MatSciScripts/{abinit.files,abinit.in} ."

#------------------------------------------- MODULES -------------------------------------------

# compilers
module load cuda/12.2
export CUDATOOLKIT_HOME="/home1/apps/cuda/12.2"

# Cuda libraries
export PATH="/home1/apps/cuda/12.2/bin/:$PATH"
export LD_LIBRARY_PATH="/home1/apps/cuda/12.2/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/lib64/:$LD_LIBRARY_PATH"

# export PATH="/scratch1/05979/uthpala/cuda/11.0/bin/:$PATH"
# export LD_LIBRARY_PATH="/scratch1/05979/uthpala/cuda/11.0/lib64/:$LD_LIBRARY_PATH"

# programs
module load cmake/3.24.2
module load autotools/1.4

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

# find-in-file - usage: fif <searchTerm> <directory>
fif() {
 if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
 if [ -z "$2" ]; then directory="./"; else directory="$2"; fi
 rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1" "$directory"\
     | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
     --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

#------------------------------------------- PATHS -------------------------------------------

# MatSciScripts
export PATH="/home1/05979/uthpala/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# nodejs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# FHIaims
export PATH="/home1/05979/uthpala/local/FHIaims/bin/:$PATH"
export PATH="/home1/05979/uthpala/local/FHIaims/utilities/:$PATH"

# globus
export PATH="/home1/05979/uthpala/local/globusconnectpersonal-3.2.0/:$PATH"

# vim
export PATH="/home1/05979/uthpala/local/vim/build/bin/:$PATH"

# Python3
# export PATH="/home1/05979/uthpala/local/Python-3.9.16/build/bin/:$PATH"
# export LD_LIBRARY_PATH="/home1/05979/uthpala/local/Python-3.9.16/build/lib/:$LD_LIBRARY_PATH"

# scalapack
export LD_LIBRARY_PATH="/home1/05979/uthpala/local/scalapack-2.2.0/:$LD_LIBRARY_PATH"

# cxxopts
export cxxopts_DIR="/home1/05979/uthpala/lib/cxxopts/build/lib64/cmake/cxxopts/"

# ripgrep
export PATH="/home1/05979/uthpala/local/ripgrep/:$PATH"

# bat
export PATH="/home1/05979/uthpala/local/bat/:$PATH"
