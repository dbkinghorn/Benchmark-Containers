#!/usr/bin/env bash

# HPL Linpack Benchmark run script for AMD processors
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
hpl-bench version: ${VERSION}
Usage:
    hpl-bench.sh 
	hpl-bench.sh [options]
Options:
	--help/-h:		    show this message
	--problem-size/-s:	problem size, Ns in HPL.dat 
                        - (default: set to use 80% of system memory)
	--num-cores/-c:		number of cores to use 
                        - (default: all "real" cores)
Examples:
    hpl-bench.sh
    - On a machine with 32 cores and 128GB memory, this will run the benchmark
      with on 32 cores and problem size of 80% of the system memory 
      (approx. 114752 for the value of Ns in HPL.dat). 
    
    hpl-bench.sh --problem-size 10000
    - Sets Ns to 10000 in HPL.dat and runs the benchmark with all "real" cores. 
    
    hpl-bench.sh -s 5000 -c 8
    - Sets Ns to 5000 in HPL.dat and runs the benchmark with 8 cores.

EOF
}

# Use a function to exec a python script to get the problem size
# that would use 80% of the system memory. (To set Ns variable in HPL.dat)
# This is passing the argument to python as an environment variable
function getNs() {
    PYARG="$1" python3 - <<EOF
import math as m
import os
sys_mem=int(os.environ['PYARG'])
print(64* m.floor(m.sqrt(sys_mem*0.8/8e-3)/64))
EOF
}

# Set default values for problem size and number of cores
# 80% of the system memory
PROBLEM_SIZE=$(getNs $(awk '/Mem/ {print $2}' /proc/meminfo))
# All "real" cores
NUM_CORES=$(awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo)

# If there are arguments, parse them, otherwise use defaults
while [ $# -gt 0 ]; do
    case "$1" in
    --help | -h)
        show_help
        exit 0
        ;;
    --problem-size | -s)
        shift
        PROBLEM_SIZE=$1
        ;;
    --num-cores | -c)
        shift
        NUM_CORES=$1
        ;;
    *)
        echo "Unknown argument: $1"
        show_help
        exit 1
        ;;
    esac
    shift
done

# Use sed to edit the HPL.dat file to set the problem size
sed -i "s/.*\bNs/${PROBLEM_SIZE}          Ns/" ./HPL.dat

echo "************************************************************************"
echo "Running HPL benchmark with ${NUM_CORES} cores and problem size of ${PROBLEM_SIZE}"
echo "************************************************************************"

# Run the HPL benchmark
OMP_NUM_THREADS=${NUM_CORES} OMP_PROC_BIND=TRUE OMP_PLACES=cores xhpl
