#
# Copyright (C) 1996-2016	The SIESTA group
#  This file is distributed under the terms of the
#  GNU General Public License: see COPYING in the top directory
#  or http://www.gnu.org/copyleft/gpl.txt.
# See Docs/Contributors.txt for a list of contributors.
#
#
SIESTA_ARCH=Linux
#
#
FC=mpif90
#
FC_ASIS=$(FC)
#
#FFLAGS=-O2
FFLAGS= -g -Wall -Wextra -O0 -g -fbacktrace -fbounds-check #-Wl-commons,use_dylibs
FFLAGS_DEBUG= -g -Wall -Wextra -O0 -g -fbacktrace -fbounds-check
LDFLAGS=
RANLIB=echo
LIBS=
SYS=nag
#
# --- Edit the location of your netcdf files
#
NETCDF_ROOT=/users/ukh0001/local/netcdf-c-4.7.4/build/
INCFLAGS=-I$(NETCDF_ROOT)/include
NETCDF_LIBS= -L$(NETCDF_ROOT)/lib -lnetcdf
DEFS_CDF= # -DCDF
#
DEFS=-DGRID_DP -DGFORTRAN -DFC_HAVE_FLUSH -DFC_HAVE_ABORT -DDMFT -DMPI_DMFT -DDEBUGDMFTWRITENKIJ #-DDEBUGDMFTWRITENKIJ_EIG  # Note this !!
#DEFS=-DGRID_DP -DGFORTRAN -DFC_HAVE_FLUSH -DFC_HAVE_ABORT -DDEBUG_PAO      # Note this !!
#COMP_LIBS= libsiestaLAPACK.a libsiestaBLAS.a
#
#
MPI_INTERFACE= libmpi_f90.a
MPI_INCLUDE= .     # Note . for no-op
DEFS_MPI= -DMPI
#
# Specify full paths to avoid picking up the veclib versions..
#

# DMFT library
DMFT_LIBS = -L//users/ukh0001/projects/DMFTwDFT/sources -ldmft

# Library root
LIBS_ROOT = /users/ukh0001/lib

LAPACK= -L$(LIBS_ROOT)/ -llapack -latlas
BLAS= -L$(LIBS_ROOT)/ -lblas
BLACS=
SCALAPACK= -L$(LIBS_ROOT)/ -lscalapack
METIS= -L$(LIBS_ROOT)/ -lmetis

FPPFLAGS:=$(DEFS_MPI) $(DEFS_CDF) $(DEFS) $(DEFS_WANNIER90)
LIBS= $(DMFT_LIBS) $(WANNIER90_LIBS) $(SCALAPACK) $(LAPACK) $(BLAS) $(NETCDF_LIBS) $(METIS) # -L/usr/lib -lSystem

#
.F.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)  $(FPPFLAGS) $<
.f.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)   $<
.F90.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)  $(FPPFLAGS) $<
.f90.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)   $<
#
