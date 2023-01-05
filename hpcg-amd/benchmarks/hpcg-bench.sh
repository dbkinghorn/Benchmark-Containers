#!/usr/bin/env bash

# HPCG Benchmark run script
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
hpcg-bench version: ${VERSION}
Usage:
    hpcg-bench.sh 
	hpcg-bench.sh [options]
Options:
	--help/-h:		    show this message
	--cores/-c:		    space separated series of length 1 or more
                        giving numbers-of-cores to use for each run 
                        - (default: 1 run of all "real" cores)
Examples:
    hpcg-bench.sh
    - run hpcg on all available cores
    
    hpcg-bench.sh -c 4 8 12 16 20 24 32
    - Runs the benchmark a series of 7 times with the listed number
     of cores for each run.
     Note: odd numbers often crash MPI.

EOF
}

# All "real" cores
NUM_CORES=$(awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo)

# If there are arguments, parse them, otherwise use defaults
while [ $# -gt 0 ]; do
    case "$1" in
    --help | -h)
        show_help
        exit 0
        ;;
    --cores | -c)
        shift
        CORE_SERIES=$* # e.g. 4 8 12 16 20 24 32
        break
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
echo "Running HPCG benchmark series with ${CORE_SERIES} cores"
echo "Results will be written to hpcg-jobs.out"
echo "************************************************************************"

# Run the HPCG benchmark
for NUM_CORES in ${CORE_SERIES}; do
    echo "Running HPCG with ${NUM_CORES} cores ..." | tee -a hpcg-jobs.out
    mpirun --allow-run-as-root -np ${NUM_CORES} --map-by l3cache --mca btl self,vader -x OMP_NUM_THREADS=1 xhpcg
    grep 'VALID' HPCG-*.txt | tee -a hpcg-jobs.out
    cat HPCG-*.txt
    rm *.txt
    sleep 4 # wait a bit for MPI processes to get cleaned up
done
