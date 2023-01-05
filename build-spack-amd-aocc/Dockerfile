# Spack Build image with AMD aocc compilers installed and ready for use with spack
FROM docker.io/spack/ubuntu-jammy 

WORKDIR /root
# You need to download a copy of aocc and accept the EULA
COPY ./aocc-compiler-3.2.0_1_amd64.deb .
RUN apt update && \
    apt install -y ./aocc-compiler-3.2.0_1_amd64.deb && \
    apt install -y vim && \
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

