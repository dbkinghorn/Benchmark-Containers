#!/bin/bash

#run xhpcg over MPI ranks

for n in 4 8 12 14 16 18 20 24 32 40 48 56 64; do
    echo $n >>test.out
    mpirun --allow-run-as-root -np $n --map-by l3cache --mca btl self,vader -x OMP_NUM_THREADS=1 xhpcg
    grep 'VALID' HPCG-*.txt | tee -a test.out
    rm *.txt
done
