#!/usr/bin/env bash

# NWChem Benchmark run script
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

VERSION=0.1.1

show_help() {
    cat <<EOF
nwchem-bench version: ${VERSION}
Usage:
    nwchem-bench.sh 
	nwchem-bench.sh [options]
Options:
	--help/-h:		    show this message
	--cores/-c:		    space separated series of length 1 or more
                        giving numbers-of-cores to use for each run 
                        - (default: 1 run of all "real" cores)
Examples:
    nwchem-bench.sh
    - run nwchem on all available cores
    
    nwchem-bench.sh -c 4 8 12 16 20 24 32
    - Runs the benchmark a series of 7 times with the listed number
     of cores for each run.
     Note: odd numbers often crash MPI.

EOF
}

# All "real" cores for default
CORE_SERIES=$(awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo)

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

tee -a nwchem-jobs.out <<EOF

* ************************************************************************
* Date:" $(date)
* Running nwchem benchmark series with ${CORE_SERIES} cores
* Results will be written to nwchem-jobs.out
* ************************************************************************
EOF

# Run the nwchem benchmark

# We need to set these since the mpi call in Allmesh is internal
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Do the job runs
for NUM_CORES in ${CORE_SERIES}; do
    #echo "Running nwchem with ${NUM_CORES} cores ..." | tee -a nwchem-jobs.out

    mpirun -np ${NUM_CORES} --map-by l3cache -x KMP_WARNINGS=0 -x OMP_NUM_THREADS=1 -x OMP_STACKSIZE="32M" nwchem ./c240_631gs.nw | tee -a nwchem-jobs.out
done

# Extract times
echo "------------------------"
echo "nwchem with ${CORE_SERIES} cores ..." | tee -a nwchem-jobs.out
echo "$(grep "Total times" ./nwchem-jobs.out | tr -s " " | cut -d " " -f 7)" | tee -a nwchem-jobs.out

# Clean up
rm -rf *.db *.movecs scratch/*
