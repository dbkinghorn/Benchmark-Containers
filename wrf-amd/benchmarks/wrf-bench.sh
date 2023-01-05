#!/usr/bin/env bash

# WRF Benchmark run script for AMD processors
#
# Puget Systems Labs
# https://pugetsystems.com
#
# Copyright 2022 Puget Systems and D B Kinghorn
# CC0 v1 license
#
# Disclaimer of Liability:
# Puget Systems and D B Kinghorn do not warrant
# or assume any legal liability or responsibility for the use of this script

set -o errexit  # exit on errors
set -o pipefail # exit on pipefail

VERSION=0.1.0

show_help() {
    cat <<EOF
wrf-bench version: ${VERSION}
The benchmark is a standard wrf run using the CONUS 12km data set

Usage:
    wrf-bench.sh 
	wrf-bench.sh [options]

Options:
	--help/-h:		    show this message
	--num-mpi/-m:	    number of MPI processes 
                        - (default: total-cores/4   (4 omp threads per core is also default)
	--num-omp/-t:	    number of OMP threads per num-mpi 
                        - (default: 4 OMP threads, (good on zen3 arch))
Examples:
    wrf-bench.sh
    - On a TR Pro 5995WX 64 cores will use 16 MPI processes and 4 OMP threads/mpi-rank
    
    wrf-bench.sh --num-mpi 8 
    - Will use 8 MPI processes and 4 OMP threads/mpi-rank (good for 32 core processors)) 
    
    wrf-bench.sh -m 8 -t 8
    - Will use 8 MPI processes and 8 OMP threads/mpi-rank (alternative for 64 core processors))

EOF
}

# Defaults
# All "real" cores
NUM_CORES=$(awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo)

# If there are arguments, parse them, otherwise use defaults
while [ $# -gt 0 ]; do
    case "$1" in
    --help | -h)
        show_help
        exit 0
        ;;
    --num-mpi | -m)
        shift
        NUM_MPI=$1
        ;;
    --num-omp | -t)
        shift
        NUM_OMP=$1
        ;;
    *)
        echo "Unknown argument: $1"
        show_help
        exit 1
        ;;
    esac
    shift
done

echo "************************************************************************"
echo "Running wrf benchmark with ${NUM_MPI} MPI ranks and ${NUM_OMP} OMP threads"
echo "************************************************************************"

# Default to 4 OMP threads per MPI rank
NUM_MPI=${NUM_MPI:-$(($NUM_CORES / 4))}
NUM_OMP=${NUM_OMP:-4}

# Run the wrf benchmark

echo "Unpacking CONUS 12km data set"
tar xf wrf_simulation_CONUS12km.tar.gz
cd conus_12km/
#WRF_LOC=$(spack location -i wrf) # location with spack install
WRF_LOC=/opt/view # location with docker image
WRF_ROOT=${WRF_LOC}/test/em_real/ 2>/dev/null
set +e # don't exit on the link error below (it's ok)
ln -s $WRF_ROOT* .
set -e
ulimit -s unlimited
wrf_exe=${WRF_LOC}/run/wrf.exe

echo "Running wrf benchmark with ${NUM_MPI} MPI ranks and ${NUM_OMP} OMP threads"
time OMP_NUM_THREADS=${NUM_OMP} mpirun -np ${NUM_MPI} --allow-run-as-root --map-by ppr:4:l3cache $wrf_exe

#clean up
rm rsl* wrfout*
