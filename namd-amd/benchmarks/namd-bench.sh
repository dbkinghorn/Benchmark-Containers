#!/usr/bin/env bash

# NAMD Benchmark run script for AMD processors
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
namd-bench version: ${VERSION}
Usage:
    namd-bench.sh 
	namd-bench.sh [options]
Options:
	--help/-h:		    show this message
	--job/-j:	        job to run, one of: apoa1, stmv, f1atpase 
                        - (default: apoa1)
	--num-cores/-c:		number of cores to use 
                        - (default: all threads, "real" cores + "hyperthreads")
Examples:
    namd-bench.sh
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the apoa1 with 128 threads
    
    namd-bench.sh --job stmv 
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the stmv with 128 threads 
    
    namd-bench.sh -j f1atpase -c 32
    - On a TR Pro 5995WX 64 cores (128 threads) this will run the f1atpase with 32 threads

EOF
}

# Defaults
# All "real"+"hyper" threads
NUM_CORES=$(nproc --all)
JOB="apoa1"

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
echo "Running namd benchmark with job ${JOB} and ${NUM_CORES} threads"
echo "************************************************************************"

# Run the namd benchmark
namd2 +p${NUM_CORES} +setcpuaffinity +idlepoll ${JOB}/${JOB}.namd | tee >(awk '/TIMING: 440/,0' | grep 'Benchmark\|WallClock')
