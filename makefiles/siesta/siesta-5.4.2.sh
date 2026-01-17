#!/bin/bash

FC=ifx CC=icx MPIFC=mpiifx cmake -S. -B_build -C cmake/toolchains/intelllvm.cmake -DCMAKE_INSTALL_PREFIX=/hpc/home/ukh/apps/siesta-5.4.2/build -DLAPACK_LIBRARY="-lmkl_intel_lp64 -lmkl_sequential -lmkl_core" -DSCALAPACK_LIBRARY="-lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core" -DSIESTA_WITH_NETCDF=OFF -DCMAKE_BUILD_TYPE=Release -DFortran_FLAGS_RELEASE="-O0"
cmake --build _build -j 8
cmake --install _build
