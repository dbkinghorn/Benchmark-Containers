# Notes on creating docker containers from spack spec files

Spack + docker looks like a decent way to create my "base" container images for complicated setups.

Procedure outline;
- Setup a build machine with spack installed + any special compilers
- Add the extra compilers to spack
- Create a spack env for the app build
- Spack install the app in the env
- Check that it built and runs correctly
- Use the env spack.yaml to generate a multi-stage Dockerfile
- Edit the Dockerfile to pull custom build spack container
- docker build
- Test the container
- Push to DockerHub

## Setup build machine
I'm using;
- Ubuntu 22.04 "jammy" server
- docker-ce
- spack 0.19.0.dev0
- AMD aocc 3.2.0 local install

## Ubuntu server
Basic Ubuntu 22.04 server install 

## docker
I would prefer to use podman but I had some trouble with that and just did a docker setup

## spack
```
git clone -c feature.manyFiles=true https://github.com/spack/spack.git ~/spack
```
Using latest dev branch 0.19.0.dev0 since stable v0.18 failed with builds.

Source the spack env setup,
```
. ~/spack/share/spack/setup-env.sh
```

## Add extra local compilers
Install from deb file is fine. Doing this local instead of with spack turned out to much easier to work with.
[https://developer.amd.com/amd-aocc/](https://developer.amd.com/amd-aocc/)

Then add the compiler to spack
```
spack compilers find
```

## Example HPL for AMD

### Create hpl-amd environment in spack
```
spack env create hpl-amd
```
Activate it
```
spacktivate hpl-amd
```

### Do build using notes from AMD
[https://developer.amd.com/spack/hpl-benchmark/](https://developer.amd.com/spack/hpl-benchmark/)

**Example: For Building HPL 2.3 with AOCC 3.2.0 and AOCL 3.1**
I modified this slightly (remove deprecated -d flag and added -j8 for parallel builds and removed the gcc compiler version 8.3.1 that was in AMD's note so that it would use the "jammy" system default 11.2. ) Add all of you cores with -j because you may be waiting a long time for all of the packages and dependencies to compile!
```
. /opt/AMD/aocc-compiler-3.2.0/setenv_AOCC.sh 

$ spack install -j8 -v hpl@2.3 +openmp %aocc@3.2.0 ^amdblis@3.1 threads=openmp ^openmpi@4.1.1 fabrics=knem target=zen3 ^knem%gcc target=zen
```

### Test the install

### Generate Dockerfile

### Create and test container image


## Examples:

### AMD build container with aocc and aocl 3.2

AOCC compiler
```
spack env create amd-build-base
spacktivate amd-build-base
spack install -v -j8 aocc@3.2.0 +license-agreed
spack cd -i aocc@3.2.0
spack compiler add $PWD
spack compilers

kinghorn@amd1:~/spack/opt/spack/linux-ubuntu22.04-zen3/aocc-3.2.0/aocc-3.2.0-4mhldx4uohcpzgauyihvljdkbj2atafq$ spack compilers
==> Available compilers
-- aocc ubuntu22.04-x86_64 --------------------------------------
aocc@3.2.0

-- gcc ubuntu22.04-x86_64 ---------------------------------------
gcc@11.2.0

kinghorn@amd1:~/spack/opt/spack/linux-ubuntu22.04-zen3/aocc-3.2.0/aocc-3.2.0-4mhldx4uohcpzgauyihvljdkbj2atafq$ clang --version
AMD clang version 13.0.0 (CLANG: AOCC_3.2.0-Build#128 2021_11_12) (based on LLVM Mirror.Version.13.0.0)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /home/kinghorn/spack/var/spack/environments/amd-build-base/.spack-env/view/bin
```

AOCL compute libraries
```
spack install -v -j8 amdblis@3.2 %aocc@3.2.0 threads=openmp
spack install -v -j8 amdlibflame@3.2 %aocc@3.2.0
spack install -v -j8 amdfftw@3.2 %aocc@3.2.0

kinghorn@amd1:~$ spack install -v amdscalapack@3.2 %aocc@3.2.0 ^amdlibflame@3.2 ^amdblis@3.2
==> Error: URLFetchStrategy requires a url for fetching.

spack install -v amdlibm@3.2 %aocc@3.2.0
==> Warning: Missing a source id for amdlibm@3.2  # FAIL



```