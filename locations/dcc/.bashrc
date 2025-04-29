# .bashrc for dcc (dcc-login.oit.duke.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

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

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

# Source for colorful terminal
source ~/.bash_prompt

# tmux
export TMUX_DEVICE_NAME=dcc
# if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
#     tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
# fi

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
# export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0
# export I_MPI_PMI_LIBRARY=/usr/lib/x86_64-linux-gnu/libpmi.so.0

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

# Modules
export MODULEPATH="/hpc/group/coursess25/ME511/modulefiles/:$MODULEPATH"
export MODULEPATH="/hpc/group/coursess25/ME511/intel/oneapi/modulefiles/:$MODULEPATH"
# export MODULEPATH="/hpc/group/blumlab/modulefiles/:$MODULEPATH"
# export MODULEPATH="/hpc/group/blumlab/intel/oneapi/modulefiles/:$MODULEPATH"

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u ukh --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
alias interact="salloc --nodes 1 --ntasks-per-node=20 --qos interactive --time 04:00:00"
#alias sac="sacct --format="JobID,JobName%-30,State,User""
#alias sac="sacct -S $(date +%Y-%m-01) -E now -X --format="JobID,JobName%-30,State,WorkDir%-150""
alias sac="sacct -X --format="JobID,JobName%-30,State,nodelist%-30,WorkDir%-150""

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from timewarp" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makejob="cp ~/dotfiles/locations/dcc/jobscript.sh ."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"
alias f='vim "$(fzf)"'
alias scratch="cd /work/ukh"
alias globus="globusconnectpersonal -start -restrict-paths /hpc/home/ukh,/work/ukh &"

#------------------------------------------- MODULES -------------------------------------------

module load cmake/3.28.3 > /dev/null

# Compiler
intel(){
    module load compiler/latest > /dev/null
    module load mkl/latest > /dev/null
    module load mpi/latest > /dev/null
}

gnu(){
    module load OpenMPI/4.1.6 > /dev/null
    # module load MPICH/3.2.1 > /dev/null
    # module load OpenBLAS/3.23 > /dev/null
}
# default
intel

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/hpc/home/ukh/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/hpc/home/ukh/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/hpc/home/ukh/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/hpc/home/ukh/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

py2(){
   for i in $(seq ${CONDA_SHLVL}); do
       conda deactivate
   done
   conda activate py2
}
py3(){
   for i in $(seq ${CONDA_SHLVL}); do
       conda deactivate
   done
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
 rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1"    "$directory"\
     | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
     --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# colored cat
# function pygmentize_cat {
#   for arg in "$@"; do
#     pygmentize -g "${arg}" 2> /dev/null || /bin/cat "${arg}"
#   done
# }
# command -v pygmentize > /dev/null && alias cat=pygmentize_cat

#------------------------------------------- PATHS -------------------------------------------

export PATH="/hpc/home/ukh/dotfiles/:$PATH"
export PATH="/hpc/home/ukh/MatSciScripts/:$PATH"

# globus
export PATH="/hpc/home/ukh/local/globusconnectpersonal-3.2.6/:$PATH"

# ripgrep
export PATH="/hpc/home/ukh/local/ripgrep/:$PATH"

# bat
export PATH="/hpc/home/ukh/local/bat/:$PATH"

# local libs
export LD_LIBRARY_PATH="/hpc/home/ukh/libs/:$LD_LIBRARY_PATH"

# lapack
export LD_LIBRARY_PATH="/hpc/home/ukh/libs/lapack-3.12.1/:$LD_LIBRARY_PATH"

# scalapack
export LD_LIBRARY_PATH="/hpc/home/ukh/libs/scalapack-2.2.2/:$LD_LIBRARY_PATH"

# FHI-aims
# export PATH="/hpc/home/ukh/local/FHIaims/FHIaims-intel/bin/:$PATH"
# export PATH="/hpc/home/ukh/local/FHIaims/FHIaims-intel/utilities/:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
