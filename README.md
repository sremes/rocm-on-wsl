# rocm-on-wsl

Simple script to setup ROCm with PyTorch on WSL Ubuntu 24.04.

We install the WSL ROCm/HSA runtime and rocminfo from the [upstream Radeon repo](https://repo.radeon.com/rocm/) their dependencies with APT, but no other ROCm libraries.

All the other needed ROCm libraries are bundled together with the PyTorch wheel that we install also from the upstream Radeon repo.
The Pytorch wheel bundles the regular Linux version of the HSA runtime, which we replace with the WSL runtime that we just installed.
