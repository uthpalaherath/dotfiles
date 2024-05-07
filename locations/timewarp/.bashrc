# .bashrc for timewarp (timewarp.egr.duke.edu)
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
export TMUX_DEVICE_NAME=timewarp
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
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
alias cat='pygmentize -g'

#export PATH=./:/globalspace/CompMatSci_2021/bin:/globalspace/CompMatSci_2021/utilities:/home/vwb3/.local/bin:/usr/local/bin:~/bin:$PATH
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
#export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0
export I_MPI_PMI_LIBRARY=/usr/lib/x86_64-linux-gnu/libpmi.so.0
# export SLURM_CPU_BIND="cores"
# unset I_MPI_PMI_LIBRARY
# export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=0
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LIBRARY_PATH

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

alias q='squeue -u ukh --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact="salloc --nodes 1 --ntasks-per-node=20 --qos interactive --time 04:00:00"

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from timewarp" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/timewarp/jobscript.sh ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"
alias f='vim "$(fzf)"'

#------------------------------------------- MODULES -------------------------------------------

# module load cmake-3.14.4
# module load git-2.37.3

intel(){
    #module unload intel-compilers-2018.4
    #module load gcc-7.5
    module load compiler/latest
    module load mkl/latest
    module load mpi/latest
    source /Space/globalspace/intel-2023.0/setvars.sh > /dev/null
    export LD_LIBRARY_PATH="/opt/intel/lib/intel64/:$LD_LIBRARY_PATH"

    # 2024
    # source /home/ukh/intel/oneapi/setvars.sh > /dev/null

    # compilers
    export CC="mpiicc"
    export CXX="mpiicpc"
    export FC="mpiifort"
    export MPICC="mpiicc"
    export MPIFC="mpiifort"
}

intel18(){
    module load intel-compilers-2018.4
    source /opt/intel/bin/compilervars.sh intel64
}

gnu(){
    # module load gcc-7.5
    # module load gcc-8.2
    module load gcc-12.2.0
    export PATH="/home/ukh/lib/openmpi-4.1.5/build/bin/:$PATH$"
    export LD_LIBRARY_PATH="/home/ukh/lib/openmpi-4.1.5/build/lib/:$LD_LIBRARY_PATH"

    # export PATH="/home/ukh/lib/mpich-3.2.1/build/bin/:$PATH"
    # export LD_LIBRARY_PATH="/home/ukh/lib/mpich-3.2.1/build/lib/:$LD_LIBRARY_PATH"
    # export MPI_ROOT="/home/ukh/lib/mpich-3.2.1/build/"

    # compilers
    export CC="mpicc"
    export CXX="mpicxx"
    export FC="mpif90"
    export MPICC="mpicc"
    export MPIFC="mpif90"

}

# default
intel

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ukh/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ukh/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ukh/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ukh/miniconda3/bin:$PATH"
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

# Get job info from job-id
jobinfo(){
    scontrol show jobid -dd $1
}

# find-in-file - usage: fif <searchTerm> <directory>
fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  if [ -z "$2" ]; then directory="./"; else directory="$2"; fi
  rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1" "$directory"\
      | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
      --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# find-in-all - usage: fia <directory> <searchTerm>
fia() {
    local directory=$1
    local pattern=$2

    # Check if the directory is provided
    if [[ -z "$directory" ]]; then
        echo "Warning: No directory provided. Searching in current directory."
        directory="."
    fi

    # Check if the directory exists
    if [[ ! -d "$directory" ]]; then
        echo "Error: The directory '$directory' does not exist."
        return 1
    fi

    # Check if the pattern is provided
    if [[ -z "$pattern" ]]; then
        echo "Warning: No search pattern provided. Listing all files."
    fi

    # Perform the search with rg and pipe the results to fzf for interactive selection
    rg --column --line-number --no-heading --color=never --smart-case --follow --hidden -g '!{node_modules,.git}' \
        "$pattern" "$directory" |
    fzf --ansi --delimiter ':' --preview "bash -c 'file=\"{1}\"; line={2}; context_lines=15; \
    start=\$((line - context_lines)); end=\$((line + context_lines)); if [ \$start -lt 1 ]; \
    then start=1; fi; filetype=\"\${file##*.}\"; tail -n +\$start \"\$file\" | head -n \$((end - start + 1)) \
        | bat --style=numbers,changes --color=always --highlight-line \$((context_lines + 1)) --language \"\$filetype\"'"
}

#------------------------------------------- PATHS -------------------------------------------

# FHI-aims
export PATH="/home/ukh/local/FHIaims/bin/:$PATH"
export PATH="/home/ukh/local/FHIaims/utilities/:$PATH"

# MatSciScripts
export PATH="/home/ukh/MatSciScripts/:$PATH"

# dotfiles
export PATH="/home/ukh/dotfiles/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"

# ctags
export PATH="/home/ukh/local/ctags-5.8/build/bin/:$PATH"

# go
export PATH="/home/ukh/local/go/bin/:$PATH"

# node
export PATH="/home/ukh/local/node-v21.7.3-linux-x64/bin/:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/node-v21.7.3-linux-x64/lib/:$LD_LIBRARY_PATH"

# libtool
export PATH="/home/ukh/local/libtool-2.4.6/build/bin/:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/libtool-2.4.6/build/lib:$LD_LIBRARY_PATH"

# globus
export PATH="/home/ukh/local/globusconnectpersonal-3.2.0/:$PATH"

# scalapack
export LD_LIBRARY_PATH="/home/ukh/lib/scalapack-2.2.0/:$LD_LIBRARY_PATH"
