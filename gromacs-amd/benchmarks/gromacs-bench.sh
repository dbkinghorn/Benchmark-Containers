#!/usr/bin/env bash

# GROMACS Benchmark run script for AMD processors
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
gromacs-bench version: ${VERSION}
Usage:
    gromacs-bench.sh 
	gromacs-bench.sh [options]
Options:
	--help/-h:		    show this message
	--job/-j:	        job to run, one of: MEM, PEP, RIB 
                        - (default: MEM)
	--num-cores/-c:		number of cores to use 
                        - (default: all threads, "real" cores + "hyperthreads")
Examples:
    gromacs-bench.sh
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the MEM with 128 threads
    
    gromacs-bench.sh --job RIB 
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the RIB with 128 threads 
    
    gromacs-bench.sh -j PEP -c 32
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the PEP with 32 threads

EOF
}

# Defaults
# All "real"+"hyper" threads
NUM_CORES=$(nproc --all)
JOB="MEM"

# If there are arguments, parse them, otherwise use defaults
while [ $# -gt 0 ]; do
    case "$1" in
    --help | -h)
        show_help
        exit 0
        ;;
    --job | -j)
        shift
        JOB=$1
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

echo "************************************************************************"
echo "Running gromacs benchmark with job ${JOB} and ${NUM_CORES} threads"
echo "************************************************************************"

case "$JOB" in
MEM)
    echo "Running MEM"
    STEPS=20000
    ;;
RIB)
    echo "Running RIB"
    STEPS=800
    ;;
PEP)
    echo "Running PEP"
    STEPS=200
    ;;
*)
    echo "Unknown job: ${JOB}"
    show_help
    exit 1
    ;;
esac

# Run the gromacs benchmark
gmx mdrun -nt ${NUM_CORES} -s ${JOB}/bench${JOB}.tpr -nsteps ${STEPS} -noconfout

#clean up
rm md.log ener.edr
