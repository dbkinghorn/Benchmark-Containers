#!/bin/bash

# Prepare cases
for i in 4 8; do
    d=run_$i
    echo "Prepare case ${d}..."
    cp -r basecase $d
    cd $d
    if [ $i -eq 1 ] 
    then
        mv Allmesh_serial Allmesh
    fi
    sed -i "s/method.*/method scotch;/" system/decomposeParDict
    sed -i "s/numberOfSubdomains.*/numberOfSubdomains ${i};/" system/decomposeParDict
    time ./Allmesh
    cd ..
done

# Run cases
for i in 4 8; do
    echo "Run for ${i}..."
    cd run_$i
    if [ $i -eq 1 ] 
    then
        simpleFoam > log.simpleFoam 2>&1
    else
        mpirun -np ${i} --map-by core simpleFoam -parallel > log.simpleFoam 2>&1
    fi
    cd ..
done

# Extract times
echo "# cores   Wall time (s):"
echo "------------------------"
for i in 4 8; do
    echo $i `grep Execution run_${i}/log.simpleFoam | tail -n 1 | cut -d " " -f 3`
done

 
 
