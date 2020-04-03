# .bashrc for spruce knob (spruce.hpc.wvu.edu)
# -Uthpala Herath


#------------------------------------------- INITIALIZATION -------------------------------------------

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
ulimit -s unlimited
module purge

# Set stty off
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi

# tmux 
module load lang/gcc/8.2.0
module load utils/tmux/3.0a
export TMUX_DEVICE_NAME=spruce
#if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    # tmux attach -t spruce || tmux new -s spruce 
    # tmux
#fi

#------------------------------------------- MODULES -------------------------------------------

# conda
#module load conda
#source /shared/software/miniconda3/etc/profile.d/conda.sh

# python
module load lang/python/intelpython_2.7.16       
module load lang/python/intelpython_3.6.3

# compilers
module load lang/intel/2018_u4

# programs
module load atomistic/abinit/8.10.2_intel18

#------------------------------------------- PATHS -------------------------------------------

# vasp
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4/bin:$PATH"
export PATH="/users/ukh0001/local/p4vasp/bin/:$PATH"
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"
export PATH="/users/ukh0001/local/VASP/vasp_dmft/:$PATH"

# dotfiles 
export PATH="/users/ukh0001/dotfiles/:$PATH"

# gsl library
export PATH="/usr/include/gsl:$PATH"

# Modules
export MODULEPATH=$MODULEPATH:/group/romero/local/privatemodules

#DMFT post processing
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
export PATH="/users/ukh0001/local/siesta/siesta-4.1-b3/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siesta-4.1-b3/Util/Bands/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestal/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestaw/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestawp/Obj/:$PATH"

# openbabel
export PATH="/users/ukh0001/local/openbabel-2.4.1/bin/:$PATH"

# local bin
export PATH=$HOME/.local/bin:$PATH

# Library path
#export LD_LIBRARY_PATH="/usr/lib64/:$LD_LIBRARY_PATH"
#export LD_LIBRARY_PATH="/usr/lib/:$LD_LIBRARY_PATH"
#export PATH="/usr/lib/:$PATH"

# vim 
#export PATH="/users/ukh0001/local/vim/bin/:$PATH"

#wannier90
export PATH="/users/ukh0001/local/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/users/ukh0001/local/wannier90/wannier90-1.2/"
export PATH="/users/ukh0001/local/wannier90/wannier90-3.1.0/:$PATH"

# MatSciScripts
export PATH="/users/ukh0001/MatSciScripts/:$PATH"


#------------------------------------------- ALIASES -------------------------------------------

alias whitehall="ssh -XC ukh0001@157.182.3.76"
alias interact="qsub -I -l nodes=1:ppn=16,walltime=168:00:00,pvmem=8gb -q alromero" ###,pvmem=8gb -q standby" ###-q alromero"
alias standby="qsub -I -l nodes=1:ppn=16,walltime=4:00:00 -q standby" ###,pvmem=8gb -q standby" ###-q alromero"
alias interact_lm="qsub -I -l nodes=1:ppn=24:broadwell:large,pvmem=20gb,walltime=20:00:00 -q alromero"
alias q="qstat -u ukh0001"
alias qq="qstat -q"
alias qstatuswatch='watch -d "qstat -u ukh0001"'
alias scratch='cd /scratch/ukh0001'
alias thorny="ssh -X ukh0001@thorny.hpc.wvu.edu"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from spruce" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
