#!/bin/bash

# TODO: update benchmark to Rodinia 3.1

# Install NVBit and build tracer
echo "Installing NVBit and building tracer..."
./util/tracer_nvbit/install_nvbit.sh
if [ $? -ne 0 ]; then
    echo "Failed to install NVBit."
    exit 1
fi

make -C ./util/tracer_nvbit/
if [ $? -ne 0 ]; then
    echo "Failed to build tracer."
    exit 1
fi

# Install Python dependencies for Accel-Sim
echo "Installing Python dependencies for Accel-Sim..."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install Python dependencies."
    exit 1
fi

# Source GPU simulator environment setup
echo "Sourcing GPU simulator environment setup..."
. ./gpu-simulator/setup_environment.sh
if [ $? -ne 0 ]; then
    echo "Failed to source GPU simulator environment setup."
    exit 1
fi

# Modify trace_drive.cc
echo "Modifying trace_drive.cc..."
sed -i 's|    : kernel_info_t(gridDim, blockDim, m_function_info) {|    : kernel_info_t(gridDim, blockDim, m_function_info, std::map<std::string, const cudaArray *>(), std::map<std::string, const textureInfo *>()) {|' \
    gpu-simulator/trace-driven/trace_driven.cc
if [ $? -ne 0 ]; then
    echo "Failed to modify trace_driven.cc."
    exit 1
fi

# Modify main.cc
echo "Modifying main.cc..."
sed -i 's|      m_gpgpu_sim->print_stats();|      m_gpgpu_sim->print_stats(finished_kernel_uid);|' \
    gpu-simulator/main.cc
if [ $? -ne 0 ]; then
    echo "Failed to modify main.cc."
    exit 1
fi

# Build the GPU simulator
echo "Building the GPU simulator..."
make -j -C ./gpu-simulator/
if [ $? -ne 0 ]; then
    echo "Failed to build GPU simulator."
    exit 1
fi

# Verify the simulation binary
ls ./gpu-simulator/bin/release
if [ $? -ne 0 ]; then
    echo "Simulation binary not found."
    exit 1
fi

# Clone the GPU application collection repository
echo "Cloning the GPU application collection repository..."
git clone https://github.com/accel-sim/gpu-app-collection
if [ $? -ne 0 ]; then
    echo "Failed to clone the GPU application collection repository."
    exit 1
fi

# Source the setup environment for the GPU application collection
echo "Sourcing the GPU application collection environment..."
. ./gpu-app-collection/src/setup_environment
if [ $? -ne 0 ]; then
    echo "Failed to source the GPU application collection environment."
    exit 1
fi

# Build a specific benchmark (Rodinia 2.0) for functional tests
echo "Building Rodinia 2.0 benchmark..."
make -j -C ./gpu-app-collection/src rodinia_2.0-ft
if [ $? -ne 0 ]; then
    echo "Failed to build Rodinia 2.0 benchmark."
    exit 1
fi

# Build the data required for benchmarks
echo "Building data required for benchmarks..."
make -C ./gpu-app-collection/src data
if [ $? -ne 0 ]; then
    echo "Failed to build benchmark data."
    exit 1
fi

echo "Setup completed successfully!"