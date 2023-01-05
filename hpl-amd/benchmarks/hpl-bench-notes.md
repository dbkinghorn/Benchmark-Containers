# hpl-amd

## Notes for running hpl 

misc. command lines
```
  288  mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_NUM_THREADS=4 xhpl
  291  mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_NUM_THREADS=4 xhpl
  301  mpi_options="$mpi_options --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores" xhpl
  302  mpirun -np 16 mpi_options="$mpi_options --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores" xhpl
  304  mpirun -np 16 $mpi_options xhpl
  306  mpirun -np 8 $mpi_options xhpl
  307  mpirun -np 16  --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores" xhpl
  309  mpirun -np 16  --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores xhpl
  310  mpirun -np 16  --map-by l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores xhpl
  311  mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x OMP_NUM_THREADS=4 xhpl
```

## Testing trials (using container image)

Simple omp first

env;
- OMP_NUM_THREADS=64
- OMP_PROC_BIND=TRUE
- OMP_PLACES=cores or maybe ll_caches ??

Experiments;
```
OMP_NUM_THREADS=64 OMP_PROC_BIND=true OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4       35000   768     1     1              18.91             1.5118e+03
HPL_pdgesv() start time Wed Aug 10 20:26:45 2022
```

```
OMP_NUM_THREADS=64 OMP_PROC_BIND=true OMP_PLACES=ll_caches xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4       35000   768     1     1              22.68             1.2606e+03
HPL_pdgesv() start time Wed Aug 10 20:30:16 2022
```

OK not too promising!  Try MPI

```
mpirun --allow-run-as-root -np 16  --map-by l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4       35000   768     4     4              28.13             1.0164e+03
HPL_pdgesv() start time Wed Aug 10 20:34:23 2022
```

```
mpirun --allow-run-as-root -np 16  --map-by ppr:2:l3cache:pe=4 -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4       35000   768     4     4              21.52             1.3284e+03
HPL_pdgesv() start time Wed Aug 10 20:36:23 2022
```

```
mpirun --allow-run-as-root -np 16  --map-by ppr:2:l3cache:pe=4 -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores --mca btl self,vader --mca mpi_leave_pinned 1 --bind-to none xhpl

sloooooooow!!! hung!
```

## trying again after update and reboot 
System seemed to be in a bad state and mixed omp mpi jobs were hanging.

```
OMP_NUM_THREADS=64 OMP_PROC_BIND=TRUE OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4       83328   768     1     1             215.40             1.7908e+03
HPL_pdgesv() start time Wed Aug 10 22:36:26 2022
```

This is pretty good. Just using OMP threads!  (larger problem size than earlier testing)

```
OMP_NUM_THREADS=64 OMP_PROC_BIND=TRUE OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4      114000   768     1     1             524.29             1.8839e+03
HPL_pdgesv() start time Wed Aug 10 23:26:50 2022
```

OK new build hpl2-amd:testing looks good!
```
OMP_NUM_THREADS=64 OMP_PROC_BIND=TRUE OMP_PLACES=cores xhpl

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4      114000   768     1     1             514.95             1.9181e+03
HPL_pdgesv() start time Thu Aug 11 01:37:08 2022
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