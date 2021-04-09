# .bashrc for bridges2 (bridges2.psc.xsede.org)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# tmux
module load tmux/2.7
export TMUX_DEVICE_NAME=bridges2
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
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

alias scratch="cd $SCRATCH"
alias q="squeue -u uthpala"
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact2="interact -N 2 -t 8:00:00 -A ph4ifjp"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from bridges2" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/bridges2/jobscript.sh ."

#------------------------------------------- MODULES -------------------------------------------

module load anaconda2/5.2.0
module load anaconda3/2019.10
module load intel/18.4    #18.0.3.222
#module load Abinit/8.4.3 #7.10.5
module load gcc/6.3.0

#------------------------------------------- PATHS -------------------------------------------

# MatSciScripts
export PATH="/home/uthpala/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# abinit
export PATH="/home/uthpala/local/abinit/abinit-8.10.2/bin/bin/:$PATH"

# wannier90
export PATH="/home/uthpala/local/wannier90/wannier90-1.2/:$PATH"
export WANNIER_DIR="/home/uthpala/local/wannier90/wannier90-1.2/"

# vasp
export PATH="/home/uthpala/local/VASP/vasp_dmft/:$PATH"
export PATH="/home/uthpala/local/VASP/vasp.5.4.4/bin/:$PATH"
export PATH="/home/uthpala/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"

# DMFTwDFT
export PATH="/home/uthpala/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/projects/DMFTwDFT/bin/"

# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
