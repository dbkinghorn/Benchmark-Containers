#! /bin/bash
#


# Run the appfile as root, which specifies 16 processes, each with its own CPU binding for OpenMP

# set the CPU governor to performance
sudo cpupower frequency-set -g performance

# Verify the knem module is loaded
#lsmod | grep -q knem
#if [ $? -eq 1 ]; then
#    echo "Loading knem module..."
#    sudo modprobe -v knem
#fi

mpi_options="--mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores"

$HOME/ompi4/aocc/bin/mpirun $mpi_options -app ./appfile_ccx
