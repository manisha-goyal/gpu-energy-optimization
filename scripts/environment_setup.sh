#!/bin/bash

LOG_FILE="environment_setup_log.txt"
> "$LOG_FILE" # Clear the log file at the start

log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Install Python dependencies for Accel-Sim
log_message "Installing Python dependencies for Accel-Sim..."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    log_message "Failed to install Python dependencies."
fi

# Source GPU simulator environment setup
log_message "Sourcing GPU simulator environment setup..."
. ./gpu-simulator/setup_environment.sh
if [ $? -ne 0 ]; then
    log_message "Failed to source GPU simulator environment setup."
fi

# Modify trace_drive.cc
log_message "Modifying trace_drive.cc..."
sed -i 's|    : kernel_info_t(gridDim, blockDim, m_function_info) {|    : kernel_info_t(gridDim, blockDim, m_function_info, std::map<std::string, const cudaArray *>(), std::map<std::string, const textureInfo *>()) {|' \
    gpu-simulator/trace-driven/trace_driven.cc
if [ $? -ne 0 ]; then
    log_message "Failed to modify trace_driven.cc."
fi

# Modify main.cc
log_message "Modifying main.cc..."
sed -i 's|      m_gpgpu_sim->print_stats();|      m_gpgpu_sim->print_stats(finished_kernel_uid);|' \
    gpu-simulator/main.cc
if [ $? -ne 0 ]; then
    log_message "Failed to modify main.cc."
fi

# Build the GPU simulator
log_message "Building the GPU simulator..."
make -j -C ./gpu-simulator/
if [ $? -ne 0 ]; then
    log_message "Failed to build GPU simulator."
fi

# Verify the simulation binary
log_message "Verifying simulation binary..."
ls ./gpu-simulator/bin/release
if [ $? -ne 0 ]; then
    log_message "Simulation binary not found."
fi

# Clone the GPU application collection repository
log_message "Cloning the GPU application collection repository..."
git clone https://github.com/accel-sim/gpu-app-collection
if [ $? -ne 0 ]; then
    log_message "Failed to clone the GPU application collection repository."
fi

# Source the setup environment for the GPU application collection
log_message "Sourcing the GPU application collection environment..."
. ./gpu-app-collection/src/setup_environment
if [ $? -ne 0 ]; then
    log_message "Failed to source the GPU application collection environment."
fi

# Build a specific benchmark (Rodinia 3.1) for functional tests
log_message "Building Rodinia 3.1 benchmark..."
make -j -C ./gpu-app-collection/src rodinia-3.1
if [ $? -ne 0 ]; then
    log_message "Failed to build Rodinia 3.1 benchmark."
fi

# Build the data required for benchmarks
log_message "Building data required for benchmarks..."
make -C ./gpu-app-collection/src data
if [ $? -ne 0 ]; then
    log_message "Failed to build benchmark data."
fi

# Unzipping trace files
log_message "Unzipping Pascal traces..."
tar -xvzf /root/accel-sim-framework/accelwattch_traces/accelwattch_pascal_traces.tgz -C /root/accel-sim-framework/accelwattch_traces
if [ $? -ne 0 ]; then
    log_message "Failed to unzip Pascal traces."
fi

log_message "Unzipping Volta traces..."
tar -xvzf /root/accel-sim-framework/accelwattch_traces/accelwattch_volta_traces.tgz -C /root/accel-sim-framework/accelwattch_traces
if [ $? -ne 0 ]; then
    log_message "Failed to unzip Volta traces."
fi

log_message "Unzipping Turing traces..."
tar -xvzf /root/accel-sim-framework/accelwattch_traces/accelwattch_turing_traces.tgz -C /root/accel-sim-framework/accelwattch_traces
if [ $? -ne 0 ]; then
    log_message "Failed to unzip Turing traces."
fi

log_message "Setup completed successfully!"