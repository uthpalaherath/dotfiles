# .bashrc for bridges2 (bridges2.psc.xsede.org)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# tmux
#module load tmux/2.7
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

alias scratch="cd /ocean/projects/phy150003p/uthpala"
alias q="squeue -u uthpala"
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact2="interact -N 1 -t 8:00:00"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from bridges2" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/bridges2/jobscript.sh ."

#------------------------------------------- MODULES -------------------------------------------

#module load gcc/10.2.0
module load intel/20.4
module load hdf5/1.12.0-intel20.4
module load parallel-netcdf/1.12.1

#------------------------------------------- FUNCTIONS -------------------------------------------

module load anaconda3/2020.11
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/packages/anaconda3/2020.11/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/packages/anaconda3/2020.11/etc/profile.d/conda.sh" ]; then
        . "/opt/packages/anaconda3/2020.11/etc/profile.d/conda.sh"
    else
        export PATH="/opt/packages/anaconda3/2020.11/bin:$PATH"
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
py2

#------------------------------------------- PATHS -------------------------------------------

# MatSciScripts
export PATH="/jet/home/uthpala/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

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
export PATH="/jet/home/uthpala/projects/DMFTwDFT_eb/bin/:$PATH"
export PYTHONPATH="/jet/home/uthpala/projects/DMFTwDFT_eb/bin/:$PYTHONPATH"

# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
export MPICC="mpiicc"
export MPIFC="mpiifort"

# NEBgen
export PATH="~/local/NEBgen/:$PATH"

# VTST
export PATH="/jet/home/uthpala/local/VTST/vtstscripts-967/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"
