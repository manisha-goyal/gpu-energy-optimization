#!/bin/bash

# Declare an associative array to map GPUs to their clock frequencies
declare -A GPU_CLOCKS
GPU_CLOCKS=(
    ["SM7_QV100"]="1132.0 1832.0"
    #["SM7_TITANV"]="1200.0 1800.0"
    #["SM75_RTX2060"]="1000 1200"
    #["SM86_RTX3070"]="1200 1400 1600"
)

# Function to extract short GPU name (e.g., QV100) from the full GPU name (e.g., SM7_QV100)
get_short_gpu_name() {
    local full_name=$1
    echo "${full_name#*_}" # Extract everything after the first underscore
}

# Set the memory clock frequency and other default domains (example: 850.0 MHz)
MEMORY_CLOCK=850.0

# Base configuration directory structure
BASE_CONFIG_DIR="./gpu-simulator/gpgpu-sim/configs/tested-cfgs"

# Results directory
RESULTS_DIR="./experiment-results"

# Function to update the clock frequencies in the gpugpusim.config file
update_clock_frequency() {
    local config_file=$1
    local core_freq=$2
    echo "Updating second clock domains in $config_file to ${core_freq}:${core_freq}:${core_freq}:${MEMORY_CLOCK}..."
    sed -i '0,/^.*-gpgpu_clock_domains .*/{n;s/^.*-gpgpu_clock_domains .*/-gpgpu_clock_domains '"${core_freq}:${core_freq}:${core_freq}:${MEMORY_CLOCK}"'/}' "$config_file"
}

# Function to copy simulation results for a given GPU and clock frequency
copy_simulation_results() {
    local sim_name=$1    # e.g., "SM7_QV100-1132.0"
    local short_gpu_name=$2    # e.g., "SM7_QV100"
    local results_dir=$3 # Base results directory, e.g., "./experiment-results"

    local sim_run_dir="./sim_run_10.1" # Simulation run directory

    # Check if the simulation run directory exists
    if [ ! -d "$sim_run_dir" ]; then
        echo "Warning: Simulation run directory ${sim_run_dir} not found. Skipping results copy."
        return
    fi

    # Iterate over all algorithms in the sim_run directory
    find "$sim_run_dir" -type d -name "${short_gpu_name}-Accelwattch_PTX_SIM" | while read -r gpu_dir; do
        # Example: ./sim_run_10.1/backprop-rodinia-2.0-ft/.../QV100-Accelwattch_PTX_SIM
        parent_dir=$(dirname "$gpu_dir") # Parent directory of the GPU-specific folder
        algo_name=$(basename "$(dirname "$parent_dir")")/$(basename "$parent_dir") # Construct relative path for algo_name

        echo "Copying results for ${algo_name}, GPU: ${sim_name}..."
        dest_dir="${results_dir}/${sim_name}/${algo_name}" # Destination directory
        mkdir -p "$dest_dir" # Ensure destination directory exists

        # Copy all files from the GPU-specific directory to the destination directory
        cp -r "$gpu_dir/"* "$dest_dir/"
    done
}

# Ensure the results directory exists
mkdir -p "$RESULTS_DIR"

# Create a timing log file
TIME_LOG_FILE="${RESULTS_DIR}/timing.log"
> "$TIME_LOG_FILE" # Clear the timing log at the start

# Loop through each GPU and its respective clock frequencies
for GPU_NAME in "${!GPU_CLOCKS[@]}"; do
    SHORT_GPU_NAME=$(get_short_gpu_name "$GPU_NAME") # Extract short GPU name
    echo "Starting simulations for GPU: $GPU_NAME"
    
    # Get the clock frequencies for this GPU
    CLOCK_FREQUENCIES=(${GPU_CLOCKS[$GPU_NAME]})
    
    # Set the config file path for the GPU
    CONFIG_FILE="${BASE_CONFIG_DIR}/${GPU_NAME}/gpgpusim.config"
    
    # Check if the config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file $CONFIG_FILE not found for GPU $GPU_NAME"
        continue
    fi
    
    # Loop through each core clock frequency for the current GPU
    for CORE_CLOCK in "${CLOCK_FREQUENCIES[@]}"; do
        echo "Running simulation for $GPU_NAME with core clock frequency: ${CORE_CLOCK} MHz"
        
        SIM_NAME="${GPU_NAME}-${CORE_CLOCK}"
        
        # Create a subdirectory for the GPU and Clock Frequency in the results directory
        GPU_RESULTS_DIR="${RESULTS_DIR}/${SIM_NAME}"
        mkdir -p "$GPU_RESULTS_DIR"
        
        # Update the clock frequency in the config file
        update_clock_frequency "$CONFIG_FILE" "$CORE_CLOCK"

        # Record the start time
        START_TIME=$(date +%s)

        # Run the simulation
        ./util/job_launching/run_simulations.py -B rodinia_2.0-ft -C "${SHORT_GPU_NAME}-Accelwattch_PTX_SIM" -N "$SIM_NAME" &
        SIM_PID=$!

        echo "Waiting for simulation process (PID: $SIM_PID) to complete..."
        wait $SIM_PID

        # Monitor the simulation progress and wait for completion
        ./util/job_launching/monitor_func_test.py -v -N "$SIM_NAME"
        
        # Record the end time
        END_TIME=$(date +%s)

        # Calculate elapsed time
        ELAPSED_TIME=$((END_TIME - START_TIME))

        # After the simulation completes, copy results
        copy_simulation_results "$SIM_NAME" "$SHORT_GPU_NAME" "$RESULTS_DIR"

        # Collect the simulation statistics
        STATS_FILE="${SIM_NAME}.csv"
        ./util/job_launching/get_stats.py -N "$SIM_NAME" | tee "${GPU_RESULTS_DIR}/${STATS_FILE}"

        # Log the elapsed time in the timing log
        echo "Simulation for ${SIM_NAME} completed in ${ELAPSED_TIME} seconds." >> "$TIME_LOG_FILE"

        echo "Simulation for ${GPU_NAME} at ${CORE_CLOCK} MHz completed. Results saved to ${GPU_RESULTS_DIR}/${STATS_FILE}"
        echo "-------------------------------------------------------------"
    done
done

echo "All simulations for all GPUs completed."