# .bashrc for perlmutter (perlmutter-p1.nersc.gov)
# and cori (cori.nersc.gov)
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

# Source for colorful terminal
source ~/.bash_prompt

# tmux
export TMUX_DEVICE_NAME=perlmutter

# Launch tmux
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
    #tmux
fi

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# ENV
NUM_CORES=$SLURM_NTASKS
WORK_DIR=$SLURM_SUBMIT_DIR

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

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

alias q='squeue -u uthpala --format="%.18i %.9P %50j %.8u %.2t %.10M %.6D %R"'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from perlmutter" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
#alias sac="sacct --format="JobID,JobName%-30,State,User""
#alias sac="sacct -S $(date +%Y-%m-01) -E now -X --format="JobID,JobName%-30,State,WorkDir%-150""
alias sac="sacct -X --format="JobID,JobName%-30,State,WorkDir%-150""

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"

alias scratch="cd $PSCRATCH"
alias makejob="cp ~/dotfiles/locations/perlmutter/jobscript.sh ."
alias interact="salloc --nodes 1 --ntasks-per-node=128 --qos interactive --time 04:00:00 --constraint cpu --account=m3337 --cpus-per-task=2"
alias interact_gpu="salloc --nodes 1 --ntasks-per-node=64 --qos interactive --time 04:00:00 --constraint gpu --gpus 4 --account=m3337_g --cpus-per-task=2"

#------------------------------------------- MODULES -------------------------------------------

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE

intel(){
    #module load craype-x86-milan
    module load PrgEnv-intel
    module load intel/2023.2.0
    #module load gpu
    #module load xpmem
    #module load craype-network-ucx
    # source /opt/intel/oneapi/setvars.sh > /dev/null
    #export I_MPI_PMI_LIBRARY=/usr/lib64/slurmpmi/libpmi.so
    #module load cudatoolkit/11.7
}

gnu(){
    module load PrgEnv-gnu
    # export MKLROOT=/opt/intel/oneapi/mkl/2023.2.0
    # export LD_LIBRARY_PATH="/opt/intel/oneapi/mkl/2023.2.0/lib/intel64/:$LD_LIBRARY_PATH"

    # module use /global/common/software/m3169/perlmutter/modulefiles
    # module load openmpi

    #export I_MPI_PMI_LIBRARY=/usr/lib64/slurmpmi/libpmi.so
    #module load craype-x86-milan
    #module load gpu
    # module load xpmem
    # module load gcc-native/12.3
    # module load cudatoolkit/12.2
    # module load craype-accel-nvidia80
    #module load craype/2.7.30
    # module load craype-network-ucx
    #module load cray-mpich-ucx/8.1.28

    #module load craype-network-ucx
    #module load gcc/12.2.0
    #module load cray-mpich-ucx
    #module load cray-ucx
    # module use /global/common/software/m3169/perlmutter/modulefiles
    # module use openmpi
}

cray(){
    module load PrgEnv-cray
    # module load craype-x86-milan
    # module load gpu
    # module load xpmem
}

#default
#gnu

# programs
module load cmake/3.24.3
# module load cray-libsci/23.09.1.1

# CUDA
export CRAY_ACCEL_TARGET=nvidia80
export LIBRARY_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$LIBRARY_PATH"
export LD_LIBRARY_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="${CUDATOOLKIT_HOME}/lib64/:$LD_LIBRARY_PATH"
export CPATH="${CUDATOOLKIT_HOME}/../../math_libs/include:$CPATH"
export CUDA_PATH="${CUDATOOLKIT_HOME}/../../math_libs/lib64/:$CUDA_PATH"

export FC=ftn
export CC=cc
export CXX=CC

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/global/homes/u/uthpala/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/global/homes/u/uthpala/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/global/homes/u/uthpala/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/global/homes/u/uthpala/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


py2(){
conda deactivate
conda activate py2
# module unload anaconda3/2020.11
# module load anaconda2/2019.10
}
py3(){
conda deactivate
conda activate py3
# module unload anaconda2/2019.10
# module load anaconda3/2020.11
}
#default
py3

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
mkcdr() {
  mkdir -p -v $1
cd $1
}
# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# find-in-file - usage: fif <searchTerm> <directory>
fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  if [ -z "$2" ]; then directory="./"; else directory="$2"; fi
  rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1" "$directory"\
      | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
      --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

#------------------------------------------- PATHS -------------------------------------------

# slate
# export LD_LIBRARY_PATH="~/local/slate-2021.05.02_default_gpu/build/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/global/u2/u/uthpala/local/slate-2021.05.02_gpu/build/opt/slate/lib/:$LD_LIBRARY_PATH"

# libraries
#export LD_LIBRARY_PATH="~/lib/BLAS-3.10.0/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/fftw-3.3.10/build/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/lapack-3.10.1/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/libxc-5.2.3/build/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="~/lib/scalapack-2.2.0/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/global/homes/u/uthpala/lib/openblas/:$LD_LIBRARY_PATH"

# FHI-aims
export PATH="/global/u2/u/uthpala/local/FHIaims/FHIaims_intel/bin/:$PATH"

# MatSciScripts
export PATH="~/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# ctags
export PATH="/global/homes/u/uthpala/local/ctags-5.8/build/bin/:$PATH"

# nodejs
export PATH="/global/homes/u/uthpala/local/node-v19.6.0/build/bin/:$PATH"

# ripgrep and bat
export PATH="/global/homes/u/uthpala/local/ripgrep/:$PATH"
export PATH="/global/homes/u/uthpala/local/bat/:$PATH"
