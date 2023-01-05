#!/bin/bash
cd $PWD/bench_template || exit
sed -i '/#include "streamLines"/c\ ' basecase/system/controlDict
sed -i '/#include "wallBoundedStreamLines"/c\ ' basecase/system/controlDict
unset FOAM_SIGFPE
export FOAM_SIGFPE=false
# Prepare cases
which snappyHexMesh
for i in 2 4 8 16; do
    d=run_$i
    echo "Prepare case ${d}..."
    cp -r basecase $d
    cd $d
    pwd
    if [ $i -eq 1 ]; then
        mv Allmesh_serial Allmesh
    elif [ $i -gt 8 ]; then
        sed -i "s|runParallel snappyHexMesh -overwrite|mpirun -np ${i} -mca btl    vader,self  --map-by hwthread -use-hwthread-cpus  snappyHexMesh -parallel    -overwrite > log.snappyHexMesh|" Allmesh
    fi
    sed -i "s/method.*/method scotch;/" system/decomposeParDict
    sed -i "s/numberOfSubdomains.*/numberOfSubdomains           ${i};/" system/decomposeParDict
    ./Allmesh
    cd ..
done
# Run cases
for i in 2 4 8 16; do
    echo "Run for ${i}..."
    cd run_$i
    if [ $i -eq 1 ]; then
        simpleFoam >log.simpleFoam 2>&1
    elif [ $i -gt 64 ]; then
        mpirun -np ${i} --map-by hwthread -use-hwthread-cpus -mca btl vader,self simpleFoam -parallel >log.simpleFoam 2>&1
        sed -i "s|mpirun -np ${i} --map-by hwthread -use-hwthread-cpus  snappyHexMesh -parallel -overwrite > log.snappyHexMesh|runParallel snappyHexMesh -overwrite|" Allmesh
    else
        mpirun -np ${i} --map-by core simpleFoam -parallel >log.simpleFoam 2>&1
    fi
    cd ..
done
echo "# cores   Wall time (s):"
echo "------------------------"
for i in 2 4 8 16; do
    echo $i "$(grep Execution run_${i}/log.simpleFoam | tail -n 1 | cut -d " " -f 3)"
done
