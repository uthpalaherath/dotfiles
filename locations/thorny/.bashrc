# .bashrc for thorny flat (thorny.hpc.wvu.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Memory
ulimit -s unlimited

# Source for colorful terminal
source ~/.bash_prompt

# set stty off
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi 

# tmux 
module load utils/tmux/3.0a
export TMUX_DEVICE_NAME=thorny
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    tmux attach -t thorny || tmux new -s thorny 
    #tmux
fi

#------------------------------------------- MODULES -------------------------------------------

# python
module load lang/python/intelpython_2.7.16    
module load lang/python/intelpython_3.6.3

# compilers
module load lang/gcc/8.2.0
module load lang/intel/2018_u4

# programs
module load atomistic/abinit/8.10.3_intel18

# libraries
module load libs/netcdf/4.x_intel18_impi18 
module load libs/fftw/3.3.8_intel18
module load libs/hdf5/1.10.5_intel18 

#------------------------------------------- PATHS -------------------------------------------

# vasp
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4/bin:$PATH"
export PATH="/users/ukh0001/local/p4vasp/bin/:$PATH"
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="/users/ukh0001/local/VASP/vasp_dmft/:$PATH"

# scripts
export PATH="/users/ukh0001/dotfiles/:$PATH"

# gsl library
export PATH="/usr/include/gsl:$PATH"

# DMFT 
#export PATH="/users/ukh0001/projects/DMFT/DFTDMFT/post_processing/ancont_PM/:$PATH"
#export PATH="/users/ukh0001/projects/DMFT/DFTDMFT/post_processing/bands/:$PATH"
#export PATH="/users/ukh0001/projects/DMFT/DFTDMFT/post_processing/dos/:$PATH"
#export PATH="/users/ukh0001/projects/DMFT/DFTDMFT/post_processing/src_files/ksum:$PATH"
#export WIEN_DMFT_ROOT="/users/ukh0001/projects/DMFT/DFTDMFT/bin/"
#export PATH="/users/ukh0001/projects/DMFT/DFTDMFT/bin:$PATH"

# DMFTwDFT
export PATH="/users/ukh0001/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/users/ukh0001/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/users/ukh0001/projects/DMFTwDFT/bin/"

# siesta
export PATH="/users/ukh0001/local/siesta/siesta-lowdin/Obj:$PATH"

# local bin
#export PATH=$HOME/.local/bin:$PATH

# vim
#export PATH="/users/ukh0001/local/vim/bin/:$PATH"

# wannier90
export PATH="/users/ukh0001/local/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/users/ukh0001/local/wannier90/wannier90-1.2/"
export PATH="/users/ukh0001/local/wannier90/wannier90-3.1.0/$PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias interact="qsub -I -l nodes=1:ppn=40,walltime=4:00:00 -q standby" 
alias q="qstat -u ukh0001"
alias qq="qstat -q"
alias qstatuswatch='watch -d "qstat -u ukh0001"'
alias scratch='cd /scratch/ukh0001'
alias cleantmux='tmux kill-session -a'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from thorny" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
 for arg
 do tmux kill-session -t "thorny $arg"
 done
}

