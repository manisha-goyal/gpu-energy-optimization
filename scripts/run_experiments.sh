#!/bin/bash

# Associative array to map GPUs to their clock frequencies
declare -A GPU_CLOCKS
GPU_CLOCKS=(
    # Pascal
    ["SM6_TITANX"]="1000.0 1200.0 1417.0 1620.0 1800.0"
    # Volta
    ["SM7_QV100"]="760.0 960.0 1132.0 1455.0 1600.0"
    # Turing
    ["SM75_RTX2060_S"]="1160.0 1365.0 1470.0 1700.0 1960.0"
)

# Function to extract short GPU name (e.g., QV100) from the full GPU name (e.g., SM7_QV100)
get_short_gpu_name() {
    local full_name=$1
    echo "${full_name#*_}" # Extract everything after the first underscore
}

# Function to determine trace path based on GPU architecture
get_trace_path() {
    local gpu_name=$1
    case "$gpu_name" in
        SM6_*) echo "accelwattch_traces/accelwattch_pascal_traces/11.0" ;;
        SM7_*) echo "accelwattch_traces/accelwattch_volta_traces/11.0" ;;
        SM75_*) echo "accelwattch_traces/accelwattch_turing_traces/11.0" ;;
        *) echo "Unknown architecture for $gpu_name"; exit 1 ;;
    esac
}

# Function to copy simulation results for a given GPU and clock frequency
copy_simulation_results() {
    local sim_name=$1    # e.g., "SM7_QV100-1132.0"
    local short_gpu_name=$2    # e.g., "QV100"
    local results_dir=$3 # Base results directory, e.g., "./experiment-results"
    local config_name=$4 # e.g., Pascal_1800.0MHZ

    local sim_run_dir="./sim_run_11.0" # Simulation run directory

    # Check if the simulation run directory exists
    if [ ! -d "$sim_run_dir" ]; then
        echo "Warning: Simulation run directory ${sim_run_dir} not found. Skipping results copy."
        return
    fi

    # Iterate over all algorithms in the sim_run directory
    find "$sim_run_dir" -type d -name "${short_gpu_name}-Accelwattch_SASS_SIM-${config_name}" | while read -r gpu_dir; do
        # Example: ./sim_run_11.0/backprop-rodinia-2.0-ft/.../QV100-Accelwattch_PTX_SIM-Pascal_1800.0MHZ
        parent_dir=$(dirname "$gpu_dir") # Parent directory of the GPU-specific folder
        algo_name=$(basename "$(dirname "$parent_dir")")/$(basename "$parent_dir") # Construct relative path for algo_name

        echo "Copying results for ${algo_name}, GPU: ${sim_name}..."
        dest_dir="${results_dir}/${sim_name}/${algo_name}/${short_gpu_name}-Accelwattch_SASS_SIM" # Destination directory
        mkdir -p "$dest_dir" # Ensure destination directory exists

        # Copy all files from the GPU-specific directory to the destination directory
        cp -r "$gpu_dir/"* "$dest_dir/"
    done
}

# Function to extract architecture prefix from GPU name
get_architecture() {
    local gpu_name=$1
    case "$gpu_name" in
        SM6_*) echo "Pascal" ;;
        SM7_*) echo "Volta" ;;
        SM75_*) echo "Turing" ;;
        *) echo "Unknown"; exit 1 ;;
    esac
}

# Results directory
RESULTS_DIR="./experiment-results"

# Ensure the results directory exists
mkdir -p "$RESULTS_DIR"

# Create a timing log file
TIME_LOG_FILE="${RESULTS_DIR}/timing.log"
> "$TIME_LOG_FILE" # Clear the timing log at the start

# Loop through each GPU and its respective clock frequencies
for GPU_NAME in "${!GPU_CLOCKS[@]}"; do
    SHORT_GPU_NAME=$(get_short_gpu_name "$GPU_NAME") # Extract short GPU name
    echo "Starting simulations for GPU: $GPU_NAME"
    
    # Get the details for this GPU
    CLOCK_FREQUENCIES=(${GPU_CLOCKS[$GPU_NAME]})
    ARCHITECTURE=$(get_architecture "$GPU_NAME")
    TRACE_PATH=$(get_trace_path "$GPU_NAME")

    # Loop through each core clock frequency for the current GPU
    for CORE_CLOCK in "${CLOCK_FREQUENCIES[@]}"; do
        echo "Running simulation for $GPU_NAME with core clock frequency: ${CORE_CLOCK} MHz"

        CONFIG_NAME="${ARCHITECTURE}_${CORE_CLOCK}MHZ"
        SIM_NAME="${GPU_NAME}-${CORE_CLOCK}"

        # Create a subdirectory for the GPU and Clock Frequency in the results directory
        GPU_RESULTS_DIR="${RESULTS_DIR}/${SIM_NAME}"
        mkdir -p "$GPU_RESULTS_DIR"

        # Record the start time
        START_TIME=$(date +%s)

        echo "Running simulation with params: -C ${SHORT_GPU_NAME}-Accelwattch_SASS_SIM-${CONFIG_NAME} -T ${TRACE_PATH} -N ${SIM_NAME}"

        # Run the simulation with appended parameters
        ./util/job_launching/run_simulations.py -B rodinia-3.1 \
            -C "${SHORT_GPU_NAME}-Accelwattch_SASS_SIM-${CONFIG_NAME}" \
            -T "$TRACE_PATH" \
            -N "$SIM_NAME" &
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
        copy_simulation_results "$SIM_NAME" "$SHORT_GPU_NAME" "$RESULTS_DIR" "$CONFIG_NAME"

        # Collect the simulation statistics
        STATS_FILE="${SIM_NAME}.csv"
        ./util/job_launching/get_stats.py -N "$SIM_NAME" | tee "${GPU_RESULTS_DIR}/${STATS_FILE}"

        # Log the elapsed time in the timing log
        echo "Simulation for ${SIM_NAME} completed in ${ELAPSED_TIME} seconds." >> "$TIME_LOG_FILE"

        echo "Simulation for ${GPU_NAME} at ${CORE_CLOCK} MHz completed in ${ELAPSED_TIME} seconds. Results saved to ${GPU_RESULTS_DIR}/${STATS_FILE}"
        echo "-------------------------------------------------------------"
    done
done

echo "All simulations for all GPUs completed."