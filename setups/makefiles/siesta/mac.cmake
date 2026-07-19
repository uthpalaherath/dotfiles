#
# Toolchain file for macOS systems
#
# Notes:
#  * Uses veclibfort for BLAS/LAPACK (gfortran-compatible Accelerate interface)
#  * Assumes MPI is available via mpif90/mpicc (can be disabled)
#  * ScaLAPACK should be installed separately or via SCALAPACK_LIBS environment variable
#  * Compatible with Homebrew and native macOS development environments
#
# Requirements:
#  * veclibfort (brew install veclibfort) for proper gfortran/Accelerate integration
#  * MPI (optional, brew install open-mpi) for parallel builds
#  * ScaLAPACK (optional, required for MPI builds)
#

# Host optimization settings
if( CMAKE_CROSSCOMPILING OR NOT SIESTA_WITH_HOST_OPTIMIZATION )
  set(_host_flags "")
else()
  set(_host_flags "-march=native")
endif()

#
# Fortran compiler settings
#
set(Fortran_FLAGS "${CMAKE_Fortran_FLAGS}"
  CACHE STRING "Build type independent Fortran compiler flags")

set(Fortran_FLAGS_RELEASE "-O3 ${_host_flags} -fallow-argument-mismatch -ffree-line-length-none"
  CACHE STRING "Fortran compiler flags for Release build")

set(Fortran_FLAGS_RELWITHDEBINFO "-g ${Fortran_FLAGS_RELEASE} -fbacktrace"
  CACHE STRING "Fortran compiler flags for Release with debug info build")

set(Fortran_FLAGS_MINSIZEREL "-Os ${_host_flags} -fallow-argument-mismatch -ffree-line-length-none"
  CACHE STRING "Fortran compiler flags for minimum size build")

set(Fortran_FLAGS_DEBUG "-g -O0 -fallow-argument-mismatch -ffree-line-length-none -fbacktrace"
  CACHE STRING "Fortran compiler flags for Debug build")

set(Fortran_FLAGS_CHECK "-g -O0 -fallow-argument-mismatch -ffree-line-length-none -fbacktrace -fcheck=all"
  CACHE STRING "Fortran compiler flags for Debug + checking build")

#
# C compiler settings
#
set(C_FLAGS "${CMAKE_C_FLAGS}"
  CACHE STRING "Build type independent C compiler flags")

set(C_FLAGS_RELEASE "-O3 ${_host_flags}"
  CACHE STRING "C compiler flags for Release build")

set(C_FLAGS_RELWITHDEBINFO "-g ${C_FLAGS_RELEASE}"
  CACHE STRING "C compiler flags for Release with debug info build")

set(C_FLAGS_MINSIZEREL "-Os ${_host_flags}"
  CACHE STRING "C compiler flags for minimum size build")

set(C_FLAGS_DEBUG "-g -Wall -pedantic"
  CACHE STRING "C compiler flags for Debug build")

#
# Library configuration for macOS
#

# Use OpenBLAS for BLAS/LAPACK (compatible with gfortran)
set(BLAS_LIBRARY "-lopenblas" CACHE STRING "BLAS library chosen")
set(LAPACK_LIBRARY "-lopenblas" CACHE STRING "LAPACK library chosen")
set(BLAS_LIBRARY_DIR "/opt/homebrew/opt/openblas/lib" CACHE STRING "BLAS library directory")
set(LAPACK_LIBRARY_DIR "/opt/homebrew/opt/openblas/lib" CACHE STRING "LAPACK library directory")

# ScaLAPACK configuration - use your installation at /Users/ukh/libs/scalapack-2.2.2/
set(SCALAPACK_LIBRARY "-L/Users/ukh/libs/scalapack-2.2.2 -lscalapack" 
  CACHE STRING "ScaLAPACK library chosen")

#
# Optional MPI configuration
#
# Uncomment the following line to disable MPI and build serial version only:
# set(SIESTA_WITH_MPI OFF CACHE BOOL "Disable MPI for serial builds")

#
# Build type configuration
#
# Default to Release build for production, can be overridden with -DCMAKE_BUILD_TYPE
set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Default build type")

#
# macOS-specific linker flags
#
# Add ld_classic for better compatibility on newer macOS versions
# This can help resolve linking issues with certain libraries
if(CMAKE_SYSTEM_VERSION VERSION_GREATER_EQUAL "22.0")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-ld_classic" 
    CACHE STRING "Linker flags for executables")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-ld_classic" 
    CACHE STRING "Linker flags for shared libraries")
endif()

#
# Additional macOS-specific considerations
#
# 1. If you encounter issues with veclibfort, you can try using Accelerate directly:
#    set(BLAS_LIBRARY "NONE" CACHE STRING "BLAS library chosen")
#    set(LAPACK_LIBRARY "NONE" CACHE STRING "LAPACK library chosen")
#    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -framework Accelerate")
#
# 2. For debugging calling convention issues, you might need:
#    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fno-underscoring")
#
# 3. If using custom MPI installations, ensure they are in PATH or set:
#    set(MPI_Fortran_COMPILER "/path/to/mpif90")
#    set(MPI_C_COMPILER "/path/to/mpicc")
#