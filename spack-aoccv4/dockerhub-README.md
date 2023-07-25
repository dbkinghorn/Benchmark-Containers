# Sapck v0.20.1 + AMD AOCCv4 compilers
This is a container image with the Spack package manager/build system v0.20.1 that includes AMD AOCC v4 compilers. This is the build image from multi-stage Dockerfiles that will be used to build scientific applications and benchmarks with targeted Zen3/4 optimizations.

## Dockerfile
 
```
# Spack Build image with AMD aocc compilers installed and ready for use with spack
FROM docker.io/spack/ubuntu-jammy:v0.20.1 

WORKDIR /root
# You need to have a downloaded copy of aocc
COPY ./aocc-compiler-4.0.0_1_amd64.deb .
RUN apt update && \
    apt install -y ./aocc-compiler-4.0.0_1_amd64.deb && \
    apt install -y vim && \
    rm -rf /var/lib/apt/lists/* && \
    rm ./aocc-compiler-4.0.0_1_amd64.deb

# Add the aocc compiler to spack
RUN . /opt/spack/share/spack/setup-env.sh && \
    . /opt/AMD/aocc-compiler-4.0.0/setenv_AOCC.sh && \
    spack compiler find && \
    echo ". /opt/AMD/aocc-compiler-4.0.0/setenv_AOCC.sh" >> /etc/profile.d/AOCC-setup.sh && \
    echo ". /opt/spack/share/spack/setup-env.sh" >> /etc/profile.d/SPACK-setup.sh

ENTRYPOINT ["/bin/bash", "--rcfile", "/etc/profile", "-l", "-c", "$*", "--" ]
CMD [ "/bin/bash" ]

```