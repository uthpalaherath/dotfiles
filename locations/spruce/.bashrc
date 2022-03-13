# .bashrc for spruce knob (spruce.hpc.wvu.edu)
# -Uthpala Herath


#------------------------------------------- INITIALIZATION -------------------------------------------

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Source .bash_prompt for colors
source ~/.bash_prompt

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
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    tmux attach -t spruce || tmux new -s spruce
    # tmux
fi

# ENV
NUM_CORES=$(( PBS_NUM_NODES*PBS_NUM_PPN ))
WORK_DIR=$PBS_O_WORKDIR

#------------------------------------------- MODULES -------------------------------------------

# Group modules
export MODULEPATH=$MODULEPATH:/group/romero/local/privatemodules

# compilers
module load lang/gcc/8.2.0
module load lang/intel/2018_u4

# programs
#module load atomistic/abinit/8.10.2_intel18

# libraries
module load libs/fftw/3.3.8_intel18
module load libs/hdf5/1.10.5_intel18

# Library path
#export LD_LIBRARY_PATH="/usr/lib64/:$LD_LIBRARY_PATH"
#export LD_LIBRARY_PATH="/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/lib/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/users/ukh0001/lib/:$LD_LIBRARY_PATH"

# python
module load python/anaconda3
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/gpfs/group/romero/local/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/gpfs/group/romero/local/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/gpfs/group/romero/local/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/gpfs/group/romero/local/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

py2(){
    conda deactivate
    conda activate py2
    #module unload lang/python/intelpython_3.6.3 
    #module load lang/python/intelpython_2.7.16 
    
}
py3(){
    conda deactivate
    conda activate py3
    #module unload lang/python/intelpython_2.7.16
    #module load lang/python/intelpython_3.6.3 
}
#default
py2



#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
for arg
do tmux kill-session -t "spruce $arg"
done
}

standbi(){
   if [ "$*" == "" ]; then
       arg=1
   else
       arg=$1
   fi
   qsub -I -l nodes=$arg:ppn=16,walltime=4:00:00 -q standby -d $PWD
}

# extract, mkcdr and archive creattion were taken from
# https://gist.github.com/JakubTesarek/8840983
# Easy extract
extract(){
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
mkcdr(){
mkdir -p -v $1
cd $1
}

# Creates an archive from given directory
mktar(){ tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz(){ tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz(){ tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

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

makejob(){
 queue=${1:-standby}
 nodes=${2:-1}
 ppn=${3:-16}
 jobname=${4:-jobname}

 case $queue in
     standby) walltime=4:00:00 ;;
     alromero) walltime=1000:00:00 ;;
     comm_mmem_day) walltime=24:00:00 ;;
     comm_mmem_week) walltime=168:00:00 ;;
     debug) walltime=00:15:00 ;;
     *) walltime=4:00:00 ;;
 esac

echo "\
#!/bin/bash
#PBS -N $jobname
#PBS -q $queue
#PBS -l walltime=$walltime
#PBS -l nodes=$nodes:ppn=$ppn #,pvmem=6gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe

source ~/.bashrc
ulimit -s unlimited

cd \$WORKDIR/
" > jobscript.sh
}


#------------------------------------------- PATHS -------------------------------------------


# vasp
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4/bin:$PATH"
# export PATH="/users/ukh0001/local/p4vasp/bin/:$PATH"
# export PATH="/users/ukh0001/local/VASP/vasp.5.4.4_dmft/bin/:$PATH"
# export PATH="/users/ukh0001/local/VASP/vasp_dmft/:$PATH"

# dotfiles 
export PATH="/users/ukh0001/dotfiles/:$PATH"

# gsl library
export PATH="/usr/include/gsl:$PATH"


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
export PATH="/users/ukh0001/projects/DMFTwDFT/scripts/:$PATH"

# siesta
export PATH="/users/ukh0001/local/siesta/siesta-4.1-b3/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siesta-4.1-b3/Util/Bands/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestal/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestaw/Obj/:$PATH"
export PATH="/users/ukh0001/local/siesta/siestawp/Obj/:$PATH"

# openbabel
export PATH="/users/ukh0001/local/openbabel-2.4.1/bin/:$PATH"

# local bin
# export PATH=$HOME/.local/bin:$PATH



# vim 
#export PATH="/users/ukh0001/local/vim/bin/:$PATH"

#wannier90
export PATH="/users/ukh0001/local/wannier90/wannier90-1.2:$PATH"
export WANNIER_DIR="/users/ukh0001/local/wannier90/wannier90-1.2/"
export PATH="/users/ukh0001/local/wannier90/wannier90-3.1.0/:$PATH"

# MatSciScripts
export PATH="/users/ukh0001/MatSciScripts/:$PATH"

# MechElastic
export PATH="/users/ukh0001/local/MechElastic/:$PATH"

# VTST
export PATH="/users/ukh0001/local/VTST/vtstscripts-967/:$PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias whitehall="ssh -XC ukh0001@157.182.3.76"
alias interact="qsub -I -l nodes=1:ppn=16,walltime=1000:00:00 -q alromero" ##,pvmem=8gb
alias standby="qsub -I -l nodes=1:ppn=16,walltime=4:00:00 -q standby" 
alias interact_lm="qsub -I -l nodes=1:ppn=24:broadwell:large,pvmem=20gb,walltime=20:00:00 -q alromero"
alias q="qstat -u ukh0001"
alias qs="qstat -u ukh0001 |tee -a ~/jobs.log"
alias qq="qstat -q"
alias qstatuswatch='watch -d "qstat -u ukh0001"'
alias scratch='cd /scratch/ukh0001'
alias thorny="ssh -X ukh0001@thorny.hpc.wvu.edu"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from spruce" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias tkill="tmux kill-session"

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
#alias makejob="cp ~/dotfiles/locations/spruce/jobscript.sh ."
alias makeabinit="cp ~/MatSciScripts/{abinit.in,abinit.files} ."
alias detach="tmux detach-client -a"
alias tkill="tmux kill-session"
alias ..="cd .."
alias cpr="rsync -ah --info=progress2"






