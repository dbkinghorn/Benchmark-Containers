# Benchmark Containers

This is a collection of container spec files used to build the images available on [https://hub.docker.com/orgs/pugetsystems/repositories](https://hub.docker.com/orgs/pugetsystems/repositories)

Most of these images are based on performance optimized application builds for specific hardware targets i.e. AMD Zen3, Zen4, Intel OneAPI, NVIDIA CUDA etc.

These container images are the basis for some of our Scientific and Machine Learning benchmarks at [Puget Systems](pugetsystems.com).

Files for each application include,

- Spack spec.yaml (build specifications with targeted optimizations)
- Dockerfiles (Multi-stage build/install)
- \*Enroot container-bundle (self running) build scripts
- Benchmarks
- Usage notes

\* Enroot container bundles are self-running containers. No container runtime (docker) install is needed. These ".run" files are generally too large to be hosted on GitHub. Download locations will be provided at a later time.