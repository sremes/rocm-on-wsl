#!/bin/bash

# Make the directory if it doesn't exist yet.
# This location is recommended by the distribution maintainers.
echo "Creating keyring directory..."
sudo mkdir --parents --mode=0755 /etc/apt/keyrings

# Download the key, convert the signing-key to a full
# keyring required by apt and store in the keyring directory
echo "Downloading ROCm GPG key..."
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# Add the ROCm repository
echo "Adding ROCm repository..."
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.4 noble main" \
    | sudo tee /etc/apt/sources.list.d/rocm.list
echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
    | sudo tee /etc/apt/preferences.d/rocm-pin-600

# Update the package list
echo "Updating package list..."
sudo apt update

# Install minimal set of ROCm packages
echo "Installing ROCm packages..."
sudo apt install -y \
    hsa-runtime-rocr4wsl-amdgpu \
    rocminfo

# Print device information
echo "Printing device information..."
/opt/rocm/bin/rocminfo | grep -A 10 "Agent"

# Install python venv
echo "Installing python venv..."
sudo apt install -y python3.12-venv python-is-python3
python -m venv ~/venv-rocm-pytorch
source ~/venv-rocm-pytorch/bin/activate
pip install numpy

# Install PyTorch with ROCm support
echo "Installing PyTorch with ROCm support..."
pip install \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4/torch-2.6.0%2Brocm6.4.0.git2fb0ac2b-cp312-cp312-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4/pytorch_triton_rocm-3.2.0%2Brocm6.4.0.git6da9e660-cp312-cp312-linux_x86_64.whl

# Replace hsa runtime with the one from local ROCm (WSL)
echo "Replacing hsa runtime with the one from ROCm..."
rm -f ~/venv-rocm-pytorch/lib/python3.12/site-packages/torch/lib/libhsa-runtime64.so*
ln -s /opt/rocm/lib/libhsa-runtime64.so ~/venv-rocm-pytorch/lib/python3.12/site-packages/torch/lib/libhsa-runtime64.so

# Test the installation
echo "Testing the installation..."
echo "NOTE: Ignore the following error: LoadLib(libhsa-amd-aqlprofile64.so) failed: libhsa-amd-aqlprofile64.so: cannot open shared object file: No such file or directory"
python -c "import torch; print('torch version: ', torch.__version__); print('cuda/hip is available:', torch.cuda.is_available()); print('num devices: ', torch.cuda.device_count()); print('device 0 name: ', torch.cuda.get_device_name(0))"

echo "Installation complete. You can now use PyTorch with ROCm support."
echo "To activate the virtual environment, run: source ~/venv-rocm-pytorch/bin/activate"
echo "To deactivate the virtual environment, run: deactivate"
echo "To remove the virtual environment, run: rm -rf ~/venv-rocm-pytorch"
echo "To remove the ROCm packages, run: sudo apt remove --purge -y hsa-runtime-rocr4wsl-amdgpu rocminfo"
echo "To remove the ROCm repository, run: sudo rm -f /etc/apt/sources.list.d/rocm.list"
echo "To remove the ROCm GPG key, run: sudo rm -f /etc/apt/keyrings/rocm.gpg"
echo "To remove the ROCm pinning, run: sudo rm -f /etc/apt/preferences.d/rocm-pin-600"
