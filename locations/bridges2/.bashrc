# .bashrc for bridges2 (bridges2.psc.xsede.org)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Source for colorful terminal
source ~/.bash_prompt

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# Fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
if [[ $- == *i* ]]; then
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
fi
export EDITOR="vim"

# PYTHON
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/jet/home/uthpala/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/jet/home/uthpala/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
mamba activate base

# Cargo
. "$HOME/.cargo/env"

#------------------------------------------- ALIASES -------------------------------------------

alias scratch="cd /ocean/projects/phy150003p/uthpala"
alias scratch2="cd /ocean/projects/che240001p/uthpala"
#alias q="squeue -u uthpala"
alias q='squeue -u $USER --format="%.18i %.9P %30j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact2="interact -N 1 -t 8:00:00"
#alias interact="interact -N 1 -t 8:00:00 --mem=2GB --ntasks-per-node=64"

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
#alias makejob="cp ~/dotfiles/locations/bridges2/jobscript.sh ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"

#------------------------------------------- MODULES -------------------------------------------

#Intel compilers
#module load intel/2021.3.0
#module load intelmpi/2021.3.0-intel2021.3.0
#source /jet/packages/intel/oneapi/setvars.sh

# module load gcc/10.2.0
# module load intel/20.4
# module load hdf5/1.12.0-intel20.4
module load parallel-netcdf/1.12.1
module load allocations

#------------------------------------------- FUNCTIONS -------------------------------------------

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

# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# Clean VASP files in current directoy and subdirectories.
# For only current directory use cleanvasp.sh
cleanvaspall(){
 find . \( \
     -name "CHGCAR*" -o \
     -name "OUTCAR*" -o \
     -name "CHG" -o \
     -name "DOSCAR" -o \
     -name "EIGENVAL" -o \
     -name "ENERGY" -o \
     -name "IBZKPT" -o \
     -name "OSZICAR*" -o \
     -name "PCDAT" -o \
     -name "REPORT" -o \
     -name "TIMEINFO" -o \
     -name "WAVECAR" -o \
     -name "XDATCAR" -o \
     -name "wannier90.wout" -o \
     -name "wannier90.amn" -o \
     -name "wannier90.mmn" -o \
     -name "wannier90.eig" -o \
     -name "wannier90.chk" -o \
     -name "wannier90.node*" -o \
     -name "PROCAR" -o \
     -name "*.o[0-9]*" -o \
     -name "vasprun.xml" -o \
     -name "relax.dat" -o \
     -name "CONTCAR*" \
 \) -type f $1
}

# Check if VASP relaxation is obtained for batch jobs when relaxed with
# Convergence.py and relax.dat is created.
relaxed (){
 if [ "$*" == "" ]; then
     arg="^[0-9]+$"
 else
     arg=$1
 fi

 rm -f unrelaxed_list.dat
 folder_list=$(ls | grep -E $arg)
 for i in $folder_list;
     do if [ -f $i/relax.dat ] ; then
            echo $i
        else
            printf "$i\t" >> unrelaxed_list.dat
        fi
     done
}

# yazi cd to directory and return default cursor
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp" || true
    echo -e -n "\x1b[6 q"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

#------------------------------------------- PATHS -------------------------------------------

# cmake
export PATH="/jet/home/uthpala/local/cmake-3.24.0/build/bin/:$PATH"

# aims
export PATH="/jet/home/uthpala/local/FHIaims/bin/:$PATH"

# MatSciScripts
export PATH="/jet/home/uthpala/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"
export PYTHONPATH="/jet/home/uthpala/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/jet/home/uthpala/dotfiles/matplotlib/"

# abinit
export PATH="/jet/home/uthpala/local/abinit/abinit-8.10.3/build/bin/:$PATH"
#export PATH="/jet/home/uthpala/local/abinit/abinit-9.4.1/build/bin/:$PATH"
#export PATH="/jet/home/uthpala/local/abinit/abinit-9.2.2/build/bin/:$PATH"
export PAWLDA="/jet/home/uthpala/local/abinit/pseudo-dojo/paw_pw_standard"
export PAWPBE="/jet/home/uthpala/local/abinit/pseudo-dojo/paw_pbe_standard"

# wannier90
export PATH="/jet/home/uthpala/local/wannier90/wannier90-3.1.0/:$PATH"

# vasp
export PATH="/jet/home/uthpala/local/VASP/vasp.5.4.4/bin/:$PATH"

# DMFTwDFT
export PATH="/jet/home/uthpala/projects/DMFTwDFT/bin/:$PATH"
export PATH="/jet/home/uthpala/projects/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="/jet/home/uthpala/projects/DMFTwDFT/bin/:$PYTHONPATH"

# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
export MPICC="mpiicc"
export MPIFC="mpiifort"

# NEBgen
export PATH="~/local/NEBgen/:$PATH"

# VTST
export PATH="/jet/home/uthpala/local/VTST/vtstscripts-972/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"

# tsase
export PYTHONPATH=$HOME/tsase:$PYTHONPATH
export PATH=$HOME/tsase/bin:$PATH

# vim
export PATH="$HOME/apps/vim/build/bin:$PATH"

# Nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#------------------------------------------- TMUX -------------------------------------------

export TMUX_DEVICE_NAME=bridges2
if [[ $- == *i* && -t 0 && -z $TMUX && $(hostname -s) == br* ]]; then
    tmux new -A -s $TMUX_DEVICE_NAME
fi
