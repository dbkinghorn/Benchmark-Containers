#!/usr/bin/env bash

# OpenFOAM Benchmark run script
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
openfoam-bench version: ${VERSION}
Usage:
    openfoam-bench.sh 
	openfoam-bench.sh [options]
Options:
	--help/-h:		    show this message
	--cores/-c:		    space separated series of length 1 or more
                        giving numbers-of-cores to use for each run 
                        - (default: 1 run of all "real" cores)
Examples:
    openfoam-bench.sh
    - run openfoam on all available cores
    
    openfoam-bench.sh -c 4 8 12 16 20 24 32
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

tee -a openfoam-jobs.out <<EOF

* ************************************************************************
* Date:" $(date)
* Running openfoam benchmark series with ${CORE_SERIES} cores
* Results will be written to openfoam-jobs.out
* ************************************************************************
EOF

# Run the openfoam benchmark

# We need to set these since the mpi call in Allmesh is internal
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Prepare the meshes
for NUM_CORES in ${CORE_SERIES}; do
    echo "Preparing openfoam mesh with ${NUM_CORES} cores ..." | tee -a openfoam-jobs.out
    d=benchrun_$NUM_CORES
    cp -r basecase $d
    cd $d
    if [ $NUM_CORES -eq 1 ]; then
        mv Allmesh_serial Allmesh
    fi
    sed -i "s/method.*/method scotch;/" system/decomposeParDict
    sed -i "s/numberOfSubdomains.*/numberOfSubdomains ${NUM_CORES};/" system/decomposeParDict
    /usr/bin/time -f %e -a -o ../openfoam-jobs.out ./Allmesh
    cd ..
done

# Do the job runs
for NUM_CORES in ${CORE_SERIES}; do
    #echo "Running openfoam with ${NUM_CORES} cores ..." | tee -a openfoam-jobs.out
    cd benchrun_$NUM_CORES
    if [ $NUM_CORES -eq 1 ]; then
        simpleFoam >log.simpleFoam 2>&1
    else
        mpirun --allow-run-as-root -np ${NUM_CORES} --map-by core simpleFoam -parallel >log.simpleFoam 2>&1
    fi
    cd ..
done

# Extract times
#echo "# cores   Wall time (s):"
echo "------------------------"
for NUM_CORES in ${CORE_SERIES}; do
    echo "openfoam with ${NUM_CORES} cores ..." | tee -a openfoam-jobs.out
    echo "$(grep Execution ./benchrun_${NUM_CORES}/log.simpleFoam | tail -n 1 | cut -d " " -f 3) seconds" | tee -a openfoam-jobs.out
done

# Clean up
rm -rf benchrun_*
