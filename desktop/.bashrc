#set stty off
if [[ -t 0 && $- = *i* ]]
then
stty -ixon
fi

##### tmux #####
export TMUX_DEVICE_NAME=desktop
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
tmux attach -t desktop || tmux new -s desktop 
#tmux
fi
###############


################################---CUSTOMIZABLE SECTION--#############################################################################################################################################

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias spruce='ssh -XYC ukh0001@spruce.hpc.wvu.edu'
alias bridges='ssh -XYC uthpala@bridges.psc.xsede.org'
alias stampede='ssh -XYC uthpala@stampede2.tacc.xsede.org'
alias whitehall='ssh -XYC ukh0001@157.182.3.76'
alias thorny="ssh -XYC ukh0001@thorny.hpc.wvu.edu"
alias spruce2="ssh -XYC ukh0001@ssh.wvu.edu"

###################################### PATHS #############################################################################
#SET MPI
export  I_MPI_SHM_LMT=shm

#VESTA
export PATH="/home/VESTA:$PATH"

#vasp 
export PATH="/home/uthpala/VASP/vasp.5.4.4/bin/:$PATH"
export PATH="/home/uthpala/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="/home/uthpala/VASP/vasp_dmft/:$PATH"

#Intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

#wannier90
export PATH="/home/uthpala/lib/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/home/uthpala/lib/wannier90/wannier90-1.2/"

#DMFT project
#export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PYTHONPATH"
#DMFT post processing
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/bands/:$PATH"

#DMFTwDFT bin
export PATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/"

#LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/opt/intel/mkl/lib/intel64/:/home/uthpala/lib/gsl/lib/:$LD_LIBRARY_PATH" 

#anaconda
export PATH="/home/uthpala/anaconda2/bin:$PATH"
export PATH="/home/uthpala/anaconda3/bin:$PATH"


#scripts
export PATH="~/dotfiles/:$PATH"

#siesta
#export PATH="/home/uthpala/siesta/siesta-4.0.1/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Bands/:$PATH"
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Util/Contrib/APostnikov/:$PATH"
export PATH="/home/uthpala/siesta/siestal/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siestaw/Obj/:$PATH"

#elk
export PATH="/home/uthpala/elk-5.2.14/src/:$PATH"
export PATH="/home/uthpala/elk-5.2.14/src/spacegroup/:$PATH"


#cc
export CXX="mpiicpc"
export CC="mpiicc"
export FC="mpiifort"

#sod
export PATH="/home/uthpala/sod/bin/:$PATH"

#supercell
export PATH="/home/uthpala/supercell-linux/:$PATH"

#globus
export PATH="/home/uthpala/globus/:$PATH"

#jmol
export PATH="/home/uthpala/jmol/:$PATH"

#julia
export PATH="/home/uthpala/julia/bin/:$PATH"

#hdf5
export HDF5_TOOLS_DIR="/home/uthpala/lib/hdf5-1.10.4/tools/"
export HDF5_ROOT="/home/uthpala/lib/hdf5-1.10.4/hdf5/bin/"
export HDF5_LIBRARIES="/home/uthpala/lib/hdf5-1.10.4/hdf5/lib/"
export HD5F_INCLUDE_DIRS="/home/uthpala/lib/hdf5-1.10.4/hdf5/include/"



############################################################## SYSTEM RELATED STUFF ##########################################################################################################
ulimit -s unlimited


# If not running interactively, don't do anything

case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

source ~/.bash_prompt


