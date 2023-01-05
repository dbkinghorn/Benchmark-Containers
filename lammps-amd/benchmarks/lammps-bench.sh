#!/usr/bin/env bash

# LAMMPS Benchmark run script for AMD processors
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
lammps-bench version: ${VERSION}
Usage:
    lammps-bench.sh 
	lammps-bench.sh [options]
Options:
	--help/-h:		    show this message
	--job/-j:	        job to run, one of: rhodo, Cu_u3, lj 
                        - (default: rhodo)
	--num-cores/-c:		number of cores to use 
                        - (default: all threads, "real" cores + "hyperthreads")
Examples:
    lammps-bench.sh
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the rhodo with 128 threads
    
    lammps-bench.sh --job Cu_u3 
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the Cu_u3 with 128 threads 
    
    lammps-bench.sh -j lj -c 32
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the lj with 32 threads

EOF
}

# Defaults
# All "real"+"hyper" threads
NUM_CORES=$(nproc --all)
JOB="rhodo"

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
echo "Running lammps benchmark with job ${JOB} and ${NUM_CORES} threads"
echo "************************************************************************"

case "$JOB" in
rhodo)
    echo "Running rhodo"
    SCALE=4
    ;;
Cu_u3)
    echo "Running Cu_u3"
    SCALE=8
    ;;
lj)
    echo "Running lj"
    SCALE=12
    ;;
*)
    echo "Unknown job: ${JOB}"
    show_help
    exit 1
    ;;
esac

# Run the lammps benchmark
mpirun --allow-run-as-root -np ${NUM_CORES} --oversubscribe --use-hwthread-cpus --map-by hwthread --bind-to core lmp -var x ${SCALE} -var y ${SCALE} -var z ${SCALE} -sf omp -in in.${JOB}

echo ""
echo "Job ${JOB} using ${NUM_CORES} threads completed"
grep "atoms$" log.lammps && grep "Performance:" log.lammps && grep "Total wall time" log.lammps

#clean up
#rm log.lammps
