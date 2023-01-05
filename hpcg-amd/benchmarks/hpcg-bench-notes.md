# hpcg-amd

Memory performance bound!

Sparse 2nd order partial differential equation, multi-grid solver using Conjugate Gradient approximation.

This is a demanding benchmark that is limited by memory subsystem performance. It was designed as compliment to HPL to give a better overall indicator of HPC systems performance.

## Notes for running hpcg 

The spack project.py file for the code compiles with openmp threads support and you can't stop that with ~openmp (you get unresolved symbol errors because the build still trys to resolve the omp directives.

I tried many runs with mixed mpi ranks and omp threads. The best results were with OMP_NUM_THREADS=1  and some number of mpi processes.

AMD's suggested run on a dual EPYC sys is,
```
export OMP_PROC_BIND=close
export OMP_PLACES=cores
Running HPCG
mpirun -np 32 ––map-by ppr:2:l3cache:pe=4 -x OMP_NUM_THREADS=4 xhpcg
```
On a TR Pro 5995WX 64 core using that with  -np 16 or 2 thread gave poor results.

Best job run on the TR Pro 5995WX was with,
```
mpirun --allow-run-as-root -np $n --map-by l3cache --mca btl self,vader -x OMP_NUM_THREADS=1 xhpcg
```

## Testing trials (using container image)
```
#!/bin/bash

#run xhpcg over MPI ranks

for n in 4 8 12 14 16 18 20 24 32 40 48 56 64; do
    echo $n >>test.out
    mpirun --allow-run-as-root -np $n --map-by l3cache --mca btl self,vader -x OMP_NUM_THREADS=1 xhpcg
    grep 'VALID' HPCG-*.txt | tee -a test.out
    rm *.txt
done
```
```
4
Final Summary::HPCG result is VALID with a GFLOP/s rating of=10.2709
8
Final Summary::HPCG result is VALID with a GFLOP/s rating of=16.8583
12
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.1695
14
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.5181
16
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.9045
18
Final Summary::HPCG result is VALID with a GFLOP/s rating of=17.4661
20
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.3265
24
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.5357
32
Final Summary::HPCG result is VALID with a GFLOP/s rating of=18.0402
40
Final Summary::HPCG result is VALID with a GFLOP/s rating of=17.236
48
Final Summary::HPCG result is VALID with a GFLOP/s rating of=16.2097
56
Final Summary::HPCG result is VALID with a GFLOP/s rating of=15.4027
64
Final Summary::HPCG result is VALID with a GFLOP/s rating of=14.7461
```





## Benchmark Usage
Since the best results were from using omp threads without mpi, that is what the hpl-amd-bench.sh script will do. Keeps things very simple for different CPU and doing scaling runs.


```
./hpl-amd-bench.sh --help
hpl-amd-bench version: 0.1.0
Usage:
    hpl-amd-bench.sh 
        hpl-amd-bench.sh [options]
Options:
        --help/-h:                  show this message
        --problem-size/-s:      problem size, Ns in HPL.dat 
                        - (default: set to use 80% of system memory)
        --num-cores/-c:         number of cores to use 
                        - (default: all "real" cores)
Examples:
    hpl-amd-bench.sh
    - On a machine with 32 cores and 128GB memory, this will run the benchmark
      with on 32 cores and problem size of 80% of the system memory 
      (approx. 114752 for the value of Ns in HPL.dat). 
    
    hpl-amd-bench.sh --problem-size 10000
    - Sets Ns to 10000 in HPL.dat and runs the benchmark with all "real" cores. 
    
    hpl-amd-bench.sh -s 5000 -c 8
    - Sets Ns to 5000 in HPL.dat and runs the benchmark with 8 cores.
```