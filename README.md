# Puget Labs Containers

This is a collection of container spec files used to build the images available on [https://hub.docker.com/orgs/pugetsystems/repositories](https://hub.docker.com/orgs/pugetsystems/repositories)

Many of these images are based on performance optimized application builds for specific hardware targets i.e. AMD Zen3, Intel OneAPI, NVIDIA CUDA etc.

These container images are the basis for some of our Scientific and Machine Learning benchmarks.

Files included for each application include,

- Spack spec.yaml build specifications
- Dockerfiles (Multi-stage)
- Enroot container-bundle (self running) build scripts
- Benchmarks
- Usage notes
