#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi  

############ tmux ###############
module load tmux/2.7
export TMUX_DEVICE_NAME=bridges
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then 
	tmux attach -t bridges || tmux new -s bridges
    #tmux
fi

##################################

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#ulimit -s unlimited
source ~/.bash_prompt
# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias scratch="cd $SCRATCH"
alias scratch2="cd /home/uthpala/bridges_scratch2/"
alias q="squeue -u uthpala"
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact2="interact -N 2 -t 8:00:00 -A ph4ifjp"

#loading module
module load anaconda2/5.2.0
module load anaconda3/2019.10
module load intel/18.4    #18.0.3.222
#module load Abinit/8.4.3 #7.10.5
module load gcc/6.3.0

##### PATHS ######

#scripts 
export PATH="~/dotfiles/:$PATH"

#abinit
export PATH="/home/uthpala/local/abinit/abinit-8.10.2/bin/bin/:$PATH"

#wannier90
export PATH="/home/uthpala/local/wannier90/wannier90-1.2/:$PATH"
export WANNIER_DIR="/home/uthpala/local/wannier90/wannier90-1.2/"

#vasp
export PATH="/home/uthpala/local/VASP/vasp_dmft/:$PATH"
export PATH="/home/uthpala/local/VASP/vasp.5.4.4/bin/:$PATH"
export PATH="/home/uthpala/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"

#DMFT
#export PATH="/home/uthpala/projects/DFTDMFT/bin/:$PATH"
#export WIEN_DMFT_ROOT="/home/uthpala/projects/DFTDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/projects/DFTDMFT/bin/:$PYTHONPATH"
#DMFT post-processing
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/src_files/ksum/:$PATH"
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/home/uthpala/projects/DFTDMFT/post_processing/bands/:$PATH"

#DMFTwDFT
export PATH="/home/uthpala/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/projects/DMFTwDFT/bin/"

#compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
