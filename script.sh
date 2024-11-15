#!/bin/bash

# Update and install required dependencies
apt update
apt --assume-yes install gcc-5 g++-5 make xutils-dev bison zlib1g-dev flex libglu1-mesa-dev \
    libxi-dev libxmu-dev freeglut3-dev wget git python3 python3-pip

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Download and install the CUDA toolkit
mkdir -p /tmp/cuda-install
cd /tmp/cuda-install
wget https://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_418.87.00_linux.run

# Ensure the installer has executable permissions
chmod +x cuda_10.1.243_418.87.00_linux.run

# Run the installer
sh cuda_10.1.243_418.87.00_linux.run --silent --toolkit --toolkitpath=$HOME/cuda

# Verify that CUDA files have been installed
if [ ! -d "$HOME/cuda/bin" ]; then
    echo "CUDA installation failed or directory is empty"
    exit 1
fi

# Clean up installation files
rm -rf /tmp/cuda-install

# Set environment variables for CUDA
export CUDA_INSTALL_PATH=$HOME/cuda
export PATH=$CUDA_INSTALL_PATH/bin:$PATH
echo "export CUDA_INSTALL_PATH=$HOME/cuda" >> ~/.bashrc
echo "export PATH=$CUDA_INSTALL_PATH/bin:\$PATH" >> ~/.bashrc

# Clone the Accel-Sim framework repository
cd $HOME
git clone https://github.com/accel-sim/accel-sim-framework.git

# Navigate to the Accel-Sim framework and update submodules
cd accel-sim-framework
git submodule update --init --recursive