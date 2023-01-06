# Notes on (not) using buildah

Motivation is to create a usable base container with spack and AMD build tools. This is to be used as a build image to do AMD based containerized spack installs.

Buildah can be used to build container images compliant with the Open Container Initiative (OCI) image specification. Images can be built based on existing images, from scratch, and using Dockerfiles. OCI images built using the Buildah command line tool (CLI) and the underlying OCI based technologies (e.g. containers/image and containers/storage) are portable and can therefore run in a Docker environment. Buildah specializes mainly in building OCI images while Podman provides a broader set of commands and functions that help you to maintain, modify and run OCI images and containers.

## Install

Podman and buildah are (finally in the Ubuntu repos starting with Ubuntu 22.04)

```
sudo apt install podman
```

That should also pull buildah as a dependency.

## First try

```
container=$(buildah from spack/ubuntu-jammy)

kinghorn@amd1:~/AMD-testing/test-build$ echo $container
ubuntu-jammy-working-container

This doesn't work!
kinghorn@amd1:~/AMD-testing/test-build$ buildah unshare
root@amd1:~/AMD-testing/test-build# mnt=$(buildah mount $container)
root@amd1:~/AMD-testing/resources# dpkg --root=$mnt -i aocc-compiler-3.2.0_1_amd64.deb

try copy
kinghorn@amd1:~/AMD-testing/test-build$ ls
aocc-compiler-3.2.0_1_amd64.deb
kinghorn@amd1:~/AMD-testing/test-build$ buildah copy $container aocc-compiler-3.2.0_1_amd64.deb /root/
9ec67222448412ba358b203b3be4311b840d07faf564cb2d2eeea1414fb07766

buildah run $container spack install -v aocc@3.2.0 +license-agreed


buildah run $container -- . /opt/spack/share/spack/setup-env.sh
```

Nope basically nothing is working right! Time to go more basic for the container.

I'll try podman with a typical docker workflow.

- Grab the jammy base spack image
- Start it rw as root
- Install aocc
- Add env setup in /etc/profile.d/
- Commit the modified container as a new jammy+spack+amd base image

Use the Force i.e. my old docker how-to's :-)

```
kinghorn@amd1:~/AMD-testing$ podman run -it -v $HOME/AMD-testing:/AMD-testing docker.io/spack/ubuntu-jammy

apt update

root@54e852ee983f:/AMD-testing/resources# apt install ./aocc-compiler-3.2.0_1_amd64.deb

root@54e852ee983f:/AMD-testing/resources# ls /opt/
AMD  spack
root@54e852ee983f:/AMD-testing/resources# cd /etc/profile.d/

cat << EOF > AMD-aocc.sh
# Get AMD aocc on the PATH
source /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh
export LD_LIBRARY_PATH=/opt/AMD/aocc-compiler-3.2.0/lib:$LD_LIBRARY_PATH
EOF

source AMD-aocc.sh


```

That installed aocc and put it on PATH

Now make it available to spack

```
root@54e852ee983f:/etc/profile.d# spack compiler find
==> Added 1 new compiler to /root/.spack/linux/compilers.yaml
    aocc@3.2.0
==> Compilers are defined in the following files:
    /root/.spack/linux/compilers.yaml
```

## Clean up and save container as new image

```
rm -rf /var/lib/apt/lists/*

exit

kinghorn@amd1:~/AMD-testing$ podman ps -a
CONTAINER ID  IMAGE                                COMMAND            CREATED         STATUS                     PORTS       NAMES
54e852ee983f  docker.io/spack/ubuntu-jammy:latest  interactive-shell  30 minutes ago  Exited (0) 4 minutes ago               beautiful_germain

kinghorn@amd1:~/AMD-testing$ podman commit 54e852ee983f spack-amd-aocc
```

## Check that the images works as expected

```
kinghorn@amd1:~/AMD-testing$ podman run -it  spack-amd-aocc
root@d75c5d7b312e:~# spack find
==> 0 installed packages
root@d75c5d7b312e:~# spack compilers
==> Available compilers
-- aocc ubuntu22.04-x86_64 --------------------------------------
aocc@3.2.0

-- gcc ubuntu22.04-x86_64 ---------------------------------------
gcc@11.2.0
root@d75c5d7b312e:~# spack  install -j8 -v hpcg@3.1 %aocc@3.2.0 +openmp target=zen3 ^openmpi@4.1.1
```

CRAP! Spack Fail! only a few packages built and there was permission denied errors.

## Try again with regular docker ... from the beginning

```
kinghorn@amd1:~/AMD-testing$ docker run  -it -v $HOME/AMD-testing:/AMD-testing spack/ubuntu-jammy

history:
    1  apt update
    2  cd /AMD-testing/
    3  ls
    4  cd resources/
    5  apt install ./aocc-compiler-3.2.0_1_amd64.deb
    6  cd /etc/profile.d/
    7  cat << EOF > AMD-aocc.sh
    8  # Get AMD aocc on the PATH
    9  source /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh
   10  export LD_LIBRARY_PATH=/opt/AMD/aocc-compiler-3.2.0/lib:$LD_LIBRARY_PATH
   11  EOF
   12  source AMD-aocc.sh
   13  spack compilers
   14  spack compiler find
   15  rm -rf /var/lib/apt/lists/*
   16  exit
   17  ls /opt/
   18  spack compliers
   19  spack compilers
   20  source /etc/profile.d/AMD-aocc.sh
   21  spack install -j8 hpcg@3.1 %aocc@3.2.0 +openmp target=zen3 ^openmpi@4.1.1


==> hpcg: Successfully installed hpcg-3.1-ea6dtixaymz3h5sdw4kwsb66xwavcpa6
```

Took around 30min to build

... but no spack.yaml file! I didn't create an env for the build ...

```
   47  spack env create hpcg
   48  spack env activate hpcg
   49  spack env list
   50  spack find
spack install -j8 hpcg@3.1 %aocc@3.2.0 +openmp target=zen3 ^openmpi@4.1.1

root@50905821bedc:~# spack install -j8 hpcg@3.1 %aocc@3.2.0 +openmp target=zen3 ^openmpi@4.1.1
==> All of the packages are already installed
==> Updating view at /opt/spack/var/spack/environments/hpcg/.spack-env/view
root@50905821bedc:~# cd /opt/spack/var/spack/environments/
root@50905821bedc:/opt/spack/var/spack/environments# ls
hpcg
root@50905821bedc:/opt/spack/var/spack/environments# ls hpcg/
spack.lock  spack.yaml
```

That was fast because everything was cached!

```
root@50905821bedc:/opt/spack/var/spack/environments/hpcg# cat spack.yaml
# This is a Spack Environment file.
#
# It describes a set of packages to be installed, along with
# configuration settings.
spack:
  # add package specs to the `specs` list
  specs: [hpcg@3.1%aocc@3.2.0+openmp arch=linux-None-zen3 ^openmpi@4.1.1]
  view: true
  concretizer:
    unify: false
```

```
root@50905821bedc:/opt/spack/var/spack/environments/hpcg# cp spack.yaml /root/

root@50905821bedc:~# spack containerize > Dockerfile
```

## This is a fixed and working Docker file

I had to add (before any spack refs)

```
. /opt/spack/share/spack/setup-env.sh && \
```

```
# Build stage with Spack pre-installed and ready to be used
FROM docker.io/dbkinghorn/spack-jammy-amd-aocc3.2.0:v0.1 as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
    &&  (echo "spack:" \
    &&   echo "  specs:" \
    &&   echo "  - hpcg@3.1%aocc@3.2.0+openmp arch=linux-None-zen3 ^openmpi@4.1.1" \
    &&   echo "  view: /opt/view" \
    &&   echo "  concretizer:" \
    &&   echo "    unify: false" \
    &&   echo "  concretization: together" \
    &&   echo "  config:" \
    &&   echo "    install_tree: /opt/software") > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN . /opt/spack/share/spack/setup-env.sh && \
    cd /opt/spack-environment && \
    spack env activate . && \
    spack install --fail-fast && \
    spack gc -y

# Strip all the binaries
RUN find -L /opt/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

# Bare OS image to run the installed executables
FROM docker.io/ubuntu:22.04

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /opt/view /opt/view
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]

```

## Examples

After struggling with AMD spack scripts for days the following finally worked and gave me a decent NAMD build

```
  282  sudo apt install gfortran
  283  spack compiler find
  284  spack install -j16 namd@2.14 %aocc@3.2.0 fftw=amdfftw  ^amdfftw@3.2 

```
Note: I had missed errors reported for charmm build that needed gfortran that wasn't installed!  ... so maybe the AMD scripts would work?? Reluctant to find out...

I got the above line worked out by simply looking at the namd package.py to see what variants there were and tried something sensible from that and it worked!

Also NAMD source is not downloadable so I had to create a spack mirror for the source tar file. And had to rename the tar file to fit spack format. That was a pain!

```
212  mkdir spack-mirror/namd
225  spack mirror add local_filesystem file://$HOME/spack-mirror


235  cd spack-mirror/
  236  ls
  237  cd namd/
  238  ls
  239  mv NAMD_2.14_Source.tar.gz namd-2.14.tar.gz

```
Another thing local install of AMD aocl does not have a env setup script but instead a module file!
so need  sudo apt install environment-modules  to get the module command to load that file.

## Examples:

Lets try NAMD again on my local AMD sys

```
spack env create namd-amd
spacktivate namd-amd
spack install -j8 -v namd@2.14 %aocc@3.2.0 target=zen3 fftw=amdfftw ^amdfftw@3.2

cd namd-test/apoa1
namd2 +p16 +setcpuaffinity +idlepoll apoa1.namd

...
Info: Benchmark time: 16 CPUs 0.0299812 s/step 0.347005 days/ns 1257.94 MB memory

```
Yay!  Worked great and performance is excellent!

Lets try GROMACS

```
spack env create gromacs-amd
spacktivate gromacs-amd

spack install -j8 -v gromacs@2022.2 %aocc@3.2.0 ~mpi +openmp +lapack +blas target=zen3  build_type=Release ^amdblis@3.2 threads=openmp ^amdlibflame@3.2 ^amdfftw@3.2 

```

Worked!  


## hpcg

env amd-hpcg

```
spack install -j64 -v hpcg@3.1 %aocc@3.2.0 +openmp target=zen3
```

This build does nearly as well as Intel xhpcg with the following mpi flags
```
mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_NUM_THREADS=1 xhpcg
```

I don't think I can do better than this without substituting the sparse mat-vec code with a library call. Not sure how to do this so may just leave it as is (and maybe use Intel for benchmarks since it works on AMD)

## hpl

```
spack install -j64 -v hpl@2.3 +openmp %aocc@3.2.0 ^amdblis@3.2 threads=openmp target=zen3
```

```
mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_NUM_THREADS=4 xhpl


================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4      114000   768     4     4             617.90             1.5985e+03
HPL_pdgesv() start time Sat Jul 23 00:42:13 2022

HPL_pdgesv() end time   Sat Jul 23 00:52:30 2022

--------------------------------------------------------------------------------
||Ax-b||_oo/(eps*(||A||_oo*||x||_oo+||b||_oo)*N)=   3.16373329e-03 ...... PASSED
================================================================================
```

This result is slightly better than olde 3995wx 
May try AMD's suggested flags and tweeks 
```
kinghorn@tr64:~/AMD-testing/hpl-test$ export OMP_NUM_THREADS=4
kinghorn@tr64:~/AMD-testing/hpl-test$ export OMP_PROC_BIND=TRUE
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_JC_NT=1
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_IC_NT=$OMP_NUM_THREADS
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_JR_NT=1
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_IR_NT=1
kinghorn@tr64:~/AMD-testing/hpl-test$ mpi_options="--allow-run-as-root --mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader"
kinghorn@tr64:~/AMD-testing/hpl-test$ mpi_options="$mpi_options --map-by ppr:1:l3cache -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores"


kinghorn@tr64:~/AMD-testing/hpl-test$ mpirun -np 8 $mpi_options xhpl
[tr64:1386552] MCW rank 7 is not bound (or bound to all available processors)
[tr64:1386550] MCW rank 6 is not bound (or bound to all available processors)
[tr64:1386544] MCW rank 0 is not bound (or bound to all available processors)
[tr64:1386549] MCW rank 5 is not bound (or bound to all available processors)
[tr64:1386545] MCW rank 1 is not bound (or bound to all available processors)
[tr64:1386547] MCW rank 3 is not bound (or bound to all available processors)
[tr64:1386548] MCW rank 4 is not bound (or bound to all available processors)
[tr64:1386546] MCW rank 2 is not bound (or bound to all available processors)

```
Every variation of that I tried was crap

one more try with the BLIS exports in place
```
mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x OMP_NUM_THREADS=4 xhpl
```
VERY GOOD!
```
================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR12R2R4      114000   768     4     4             537.44             1.8378e+03
HPL_pdgesv() start time Sat Jul 23 02:05:08 2022

HPL_pdgesv() end time   Sat Jul 23 02:14:05 2022

--------------------------------------------------------------------------------
||Ax-b||_oo/(eps*(||A||_oo*||x||_oo+||b||_oo)*N)=   3.24815052e-03 ...... PASSED
================================================================================

```

All together that was,
```
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_JC_NT=1
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_IC_NT=$OMP_NUM_THREADS
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_JR_NT=1
kinghorn@tr64:~/AMD-testing/hpl-test$ export BLIS_IR_NT=1

mpirun -np 16 --map-by ppr:2:l3cache:pe=4 --report-bindings  -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x OMP_NUM_THREADS=4 xhpl

HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N) 
114000    83328 16000 104448       Ns
1            # of NBs
768          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
4            Ps
4            Qs
...

```


## Making a spack container with aocc

AMD has a restrictive EULA (mother fuckers) so I can't have a proper build container with aocc on docker hub!  That means I need to find a private repo or build it from scratch when I need it on a system.

Spack gets updated often so having a Dockerfile to do a build container is probably a good idea. 

Make a spack env for aocc and install aocc
```
spack env create aocc
spacktivate aocc

spack install -j64 -v aocc@3.2.0 +license-agreed

EULA license opens in vim so do
[esc] :wq  
to save a copy then the install will finish
```

Make Dockerfile
```
cd ~/spack/var/spack/environments/aocc/
cp spack.yaml ~/docker-build/spack-jammy-amd-aocc3.2.0/
cd ~/docker-build/spack-jammy-amd-aocc3.2.0/

spack containerize > Dockerfile
```

Edit created Dockerfile to desired specs
- Ubuntu jammy (22.04) spack build base (latest)
```
# Build stage with Spack pre-installed and ready to be used
FROM spack/ubuntu-jammy:latest as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo "spack:" \
&&   echo "  specs:" \
&&   echo "  - aocc@3.2.0+license-agreed" \
&&   echo "  view: /opt/view" \
&&   echo "  concretizer:" \
&&   echo "    unify: false" \
&&   echo "  concretization: together" \
&&   echo "  config:" \
&&   echo "    install_tree: /opt/software") > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# Strip all the binaries
RUN find -L /opt/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

# Bare OS image to run the installed executables
FROM ubuntu:22.04

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /opt/view /opt/view
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]

```
FAIL! Tried many things and it always fails with some kind of mgs like,
```
==> Error: Detected permission issues with the following scopes:

        [scope=env:/opt/spack-environment, cfg=/opt/spack-environment/spack.yaml]

Either ensure that you have sufficient permissions to modify these files or do not include these scopes in the update.
```

## Make spack containers with aocc 2nd try (buildah)
I'll try buildah again. Running as root. 
- make a new working container from spack-jammy
- copy aocc....deb to /root in container
- run apt update && apt install
- run spack compilers find
- cleanup
- commit 

Put a copy of aocc deb file in PWD
SIDE NOTE: I downloaded the .deb on local sys. I have to jump-host with ssh to destination so I used.
```
rsync -av -e 'ssh -J 172.17.1.50'  aocc-compiler-3.2.0_1_amd64.deb 172.17.119.227:~/
```

```
sudo -s
container=$(buildah from docker.io/spack/ubuntu-jammy)
buildah copy $container aocc-compiler-3.2.0_1_amd64.deb /root/
buildah run $container -- bash -c "apt update && apt install -y /root/aocc-compiler-3.2.0_1_amd64.deb && rm -rf /var/lib/apt/lists/*"
buildah run $container -- bash -c ". /opt/spack/share/spack/setup-env.sh && . /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh && spack compiler find && spack compilers"
buildah commit $container spack-jammy-aocc:testing
```
YES that worked!

Translating that to a regular Dockerfile
```
# Spack Build image with AMD aocc compilers installed and ready for use with spack
FROM docker.io/spack/ubuntu-jammy 

WORKDIR /root
# You need to download a copy of aocc and accept the EULA
COPY ./aocc-compiler-3.2.0_1_amd64.deb .
RUN apt update && \
    apt install -y ./aocc-compiler-3.2.0_1_amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    rm ./aocc-compiler-3.2.0_1_amd64.deb

# Add the aocc compiler to spack
RUN . /opt/spack/share/spack/setup-env.sh && \
    . /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh && \
    spack compiler find && \
    echo ". /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh" >> /etc/profile.d/AOCC-setup.sh && \
    echo ". /opt/spack/share/spack/setup-env.sh" >> /etc/profile.d/SPACK-setup.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]

```

That worked and I created spack-jammy-aocc:testing with it.

Now, we try to use that container to create a spec file for hpcg.
Yes, that works. I can use the container to do a build and generate a spec and Dockerfile. This is no docker install in the container so I can't do the image build there.

```
cd hpl-amd
cp ~/spack/var/spack/environments/amd-hpl/spack.yaml .
spack containerize > Dockerfile
docker build -t hpl-amd:testing .
docker tag hpl-amd:testing pugetsystems/hpl-amd:testing 
docker push pugetsystems/hpl-amd:testing 
```


## creating a build cache
Installing locally creates all of the build artifacts but then creating a docker image using my build container redoes all of that because it's not present in the container. So, we try to do a build cache after a local install and then mount that into the build container for the application image build.

Create a local build cache
```
spack buildcache create --unsigned --allow-root -d $PWD/spack-cache lammps

spack buildcache update-index -d $PWD/spack-cache/
```
Note, I had to use $PWD instead of "./", it failed without -a --allow-root, also needed a gpg key which I bypassed with --unsigned  (might need -r --rel too??)

Now I should be able to mount that into the build container and create a mirror like what was done with namd ... lets see :-)

```
cp ~/spack/var/spack/environments/lammps-amd/spack.yaml .
spack containerize > Dockerfile
```
Edit,
```
# Build stage with Spack pre-installed and ready to be used
FROM docker.io/dbkinghorn/spack-jammy-aocc:testing as builder

# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
&&  (echo "spack:" \
&&   echo "  specs:" \
&&   echo "  - lammps@20220623%aocc@3.2.0+asphere+class2+granular~kim+kspace+manybody+molecule+mpiio+openmp+openmp-package+opt+replica+rigid build_type=Release arch=linux-None-zen3 ^amdfftw@3.2 ^openmpi fabrics=auto" \
&&   echo "  view: /opt/view" \
&&   echo "  concretizer:" \
&&   echo "    unify: true" \
&&   echo "  concretization: together" \
&&   echo "  config:" \
&&   echo "    install_tree: /opt/software") > /opt/spack-environment/spack.yaml

# Use a build cache mirror from the build context 
COPY spack-cache/build_cache/* /spack-cache/build_cache/

# Initialize spack add the namd mirror and install the software, remove unnecessary deps
RUN . /opt/spack/share/spack/setup-env.sh && \
    spack mirror add local_filesystem file:///spack-cache && \
    spack mirror list && \
    cd /opt/spack-environment && \
    spack env activate . && \
    spack install --fail-fast && \
    spack gc -y

# Strip all the binaries
RUN find -L /opt/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

# Bare OS image to run the installed executables
FROM ubuntu:22.04

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /opt/view /opt/view
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]
```

This seems to work but is still slow to build. No, it's not finding packages that were built locally with aocc. I'll try adding --rel to see if it's a path thing??


## mirror notes for build-cache

trying to do one for hpl-amd
```
spacktivate -p  hpl-amd
spack mirror create -d ./spack-mirror -a
```
That created a source mirror for all packages in the env.

```
spack mirror add hpl-mirror file://$PWD/spack-mirror
```

Adds a mirror in the env called hpl-mirror

```
spack buildcache keys --install --trust
```
trust the gpg keys that the packages are signed with

```
spack config add "config:install_tree:padded_length:128"
spack install -j32 --no-cache
```
Quirk for build cache ... then build all the packages in the source mirror fresh with this padding. Use --no-cache to force a rebuild. 


Then there is the gpg setup
```
spack gpg create "My Name" "<my.email@my.domain.com>"
mkdir ~/private_gpg_backup
cp ~/spack/opt/spack/gpg/*.gpg ~/private_gpg_backup
cp ~/spack/opt/spack/gpg/pubring.* ~/mirror
```

Then a funny looking script to add the binaries one at a time??!
```
for ii in $(spack find --format "yyy {version} /{hash}" |
	    grep -v -E "^(develop^master)" |
	    grep "yyy" |
	    cut -f3 -d" ")
do
  spack buildcache create -af -d ~/mirror --only=package $ii
done
```
OK, yes, all of this magic worked :-)

## Use a build cache in a container build

Now the reason for doing the above.
The magic happens with,
```
# Use a local spack mirror and build-cache to speed up the build
COPY spack-mirror /spack-mirror/

# Setup mirror, install and remove unnecessary deps
RUN . /opt/spack/share/spack/setup-env.sh && \
    cd /opt/spack-environment && \
    spack env activate . && \
    spack mirror add hpl-mirror file:///spack-mirror && \
    spack buildcache keys --install --trust --force && \
    #spack buildcache update-index -d /spack-mirror && \
    spack mirror list && \
    spack install --fail-fast && \
    spack gc -y
```

## hpcg-amd example (using unsigned packages because key handling is crazy)

The mistake I was making with the keys was (following docs) and cp pubring.* since that copies 2 keys if you have done this more than once!  Then spack doesn't know which one to use and defaults to none and the docker build fails.
Solution should be to only copy 1 key  the ~ backup was causing the trouble. Just copy pubring.kbx

However, it makes sense to do this without signing since I'm building containers from my local build cache.

```
spack env create hpcg-amd
spacktivate -p hpcg-amd

spack config add "config:install_tree:padded_length:128"

spack install -j32 -v --no-cache hpcg@3.1%aocc@3.2.0+openmp target=zen3 ^openmpi@4.1.1

cp ~/spack/var/spack/environments/hpcg-amd/spack.yaml .

spack mirror create -d $PWD/spack-mirror --all
spack mirror add hpcg-mirror file://$PWD/spack-mirror

#spack gpg create "dbk" "don@pugetsystems.com"
#cp ~/spack/opt/spack/gpg/pubring.* ./spack-mirror
#spack buildcache keys --install --trust

# run create-buildcache.sh listed below
for ii in $(spack find --format "yyy {version} /{hash}" |
	    grep -v -E "^(develop^master)" |
	    grep "yyy" |
	    cut -f3 -d" ")
do
  spack buildcache create -af -d $PWD/spack-mirror -u --only=package $ii
done
# -u means unsigned

./create-buildcache.sh
spack buildcache update-index -d $PWD/spack-mirror/

spack containerize

# Edit dockerfile to use buildcache and add benchmarks

# Build stage with Spack pre-installed and ready to be used
FROM docker.io/dbkinghorn/spack-jammy-aocc:testing as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
    &&  (echo "spack:" \
    &&   echo "  specs:" \
    &&   echo "  - hpcg@3.1%aocc@3.2.0+openmp arch=linux-None-zen3 ^openmpi@4.1.1" \
    &&   echo "  view: /opt/view" \
    &&   echo "  concretizer:" \
    &&   echo "    unify: true" \
    &&   echo "  config:" \
    &&   echo "    install_tree: /opt/software") > /opt/spack-environment/spack.yaml

# Use a local spack mirror and build-cache to speed up the build
COPY spack-mirror /spack-mirror/

# Setup mirror, install and remove unnecessary deps
RUN . /opt/spack/share/spack/setup-env.sh && \
    cd /opt/spack-environment && \
    spack env activate . && \
    spack mirror add hpcg-mirror file:///spack-mirror && \
    #spack buildcache keys --install --trust --force && \
    #spack buildcache update-index -d /spack-mirror && \
    spack mirror list && \
    spack install --fail-fast --no-check-signature && \
    spack gc -y

# Strip all the binaries
RUN find -L /opt/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -s

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . >> /etc/profile.d/z10_spack_environment.sh

# Bare OS image to run the installed executables
FROM ubuntu:22.04

COPY benchmarks /benchmarks/

# Add libomp.so that the build leaves out!
# Put it in /usr/lib to be certain it is found!
COPY --from=builder /opt/AMD/aocc-compiler-3.2.0/lib/libomp.so /usr/lib/

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /opt/view /opt/view
COPY --from=builder /etc/profile.d/z10_spack_environment.sh /etc/profile.d/z10_spack_environment.sh

WORKDIR /benchmarks
ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]


docker build -t hpcg-amd:0.1.1 .


```

## In a nutshell
```
spack env create hpcg-amd
spacktivate -p hpcg-amd

spack config add "config:install_tree:padded_length:128"

spack install -j32 -v --no-cache hpcg@3.1%aocc@3.2.0+openmp target=zen3 ^openmpi@4.1.1

cp ~/spack/var/spack/environments/hpcg-amd/spack.yaml .

spack mirror create -d $PWD/spack-mirror --all
spack mirror add hpcg-mirror file://$PWD/spack-mirror

./create-buildcache.sh
spack buildcache update-index -d $PWD/spack-mirror/

spack containerize > Dockerfile

# edit Dockerfile
FROM docker.io/dbkinghorn/spack-jammy-aocc:0.1.1 as builder
...
# Use a local spack mirror and build-cache to speed up the build
COPY spack-mirror /spack-mirror/

# Initialize spack add the namd mirror and install the software, remove unnecessary deps
RUN . /opt/spack/share/spack/setup-env.sh && \
    cd /opt/spack-environment && \
    spack env activate . && \
    spack mirror add namd-mirror file:///spack-mirror && \
    spack mirror list && \
    spack install --fail-fast --no-check-signature && \
    spack gc -y
...
FROM ubuntu:22.04

COPY benchmarks /benchmarks/

# Add libomp.so that the build leaves out!
# Put it in /usr/lib to be certain it is found!
COPY --from=builder /opt/AMD/aocc-compiler-3.2.0/lib/libomp.so /usr/lib/
...
WORKDIR /benchmarks
...

docker build -t hpcg-amd:0.1.1 .

```


## Full container build procedure with spack

- install spack
- add local resources like compilers
- create spack env for app
- spack install app with build options
- create spack mirror in env dir
- create spack build cache
- create custom spack-build container if needed
- spack containerize app
- mod Dockerfile to use mirror and custom build image
- docker build

## Intel wrf build
grabbed this from https://weather.hpcworkshops.com/03-wrf/01-spack-install-wrf.html
```
spack install -j $SLURM_CPUS_ON_NODE wrf%intel build_type=dm+sm ^intel-oneapi-mpi+external-libfabric
```

## WRF benchmark
This one is a little awkward 

```
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/wrf_cloud/wrf_simulation_CONUS12km.tar.gz
tar xf wrf_simulation_CONUS12km.tar.gz

cd conus_12km/
WRF_ROOT=$(spack location -i wrf)/test/em_real/
ln -s $WRF_ROOT* .

ulimit -s unlimited
ulimit -a

wrf_exe=$(spack location -i wrf)/run/wrf.exe
time OMP_NUM_THREADS=1  mpirun -np 64 $wrf_exe
```
clean up with rm rsl* wrfout*

data is big,

du -sh *
3.6G    conus_12km
534M    wrf_simulation_CONUS12km.tar.gz

mixed omp mpi
time OMP_NUM_THREADS=4  mpirun -np 16 --map-by ppr:4:l3cache  $wrf_exe

11m5  all mpi was a bit over 13m

time OMP_NUM_THREADS=8  mpirun -np 8 --map-by ppr:8:l3cache  $wrf_exe
real    10m45.143s

time OMP_NUM_THREADS=64  $wrf_exe
real    12m9.504s