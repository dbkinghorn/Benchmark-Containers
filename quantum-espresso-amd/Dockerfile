# Build stage with Spack pre-installed and ready to be used
FROM docker.io/dbkinghorn/spack-jammy-aocc:0.1.1 as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir /opt/spack-environment \
    &&  (echo "spack:" \
    &&   echo "  specs:" \
    &&   echo "  - quantum-espresso@7.1%aocc@3.2.0+elpa+openmp hdf5=parallel arch=linux-None-zen3 ^amdblis@3.2 threads=openmp ^amdfftw@3.2 ^amdlibflame@3.2 ^amdscalapack@3.2 ^elpa@2019.11.001 ^openmpi" \
    &&   echo "  view: /opt/view" \
    &&   echo "  concretizer:" \
    &&   echo "    unify: true" \
    &&   echo "  config:" \
    &&   echo "    install_tree: /opt/software") > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
# xxd creates hex dumps and usually installed along with vim. We need to add it.
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

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]

