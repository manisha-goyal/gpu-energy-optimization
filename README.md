# GPU Energy Optimization

This project focuses on optimizing GPU energy consumption using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It explores strategies such as clock frequency adjustments and **Dynamic Voltage and Frequency Scaling (DVFS)** policies to reduce energy usage in computation, memory, and shared memory-intensive programs. The goal is to maintain performance while contributing to sustainable and efficient GPU operations.

## Singularity Setup (Using docker image)

### Step 1: Create a working directory in scratch
```bash
cd /scratch/
mkdir fa24-gpu-project-group29-energy-consumption
cd fa24-gpu-project-group29-energy-consumption
```

### Step 2: Change Singularity cache dir
```bash
export SINGULARITY_CACHEDIR=$(pwd)
source ~/.bashrc
```

### Step 3: Pull and Build our Docker Image
```bash
singularity pull docker://akubal/ubuntu-gcc-cuda
singularity build --sandbox extracted_container ubuntu-gcc-cuda_latest.sif
```

### Step 4: Start singularity container
```bash
singularity exec --writable --no-home --cleanenv extracted_container /bin/bash --rcfile /root/.bashrc
export HOME=/root
cd /root
```

### Step 5: Copy AccelWattch Traces to appropriate directory
```bash
cp -r /root/accel-sim-framework/accelwattch_traces/ /root/
```

## Accel-Sim Setup

### Step 1: Setup Environment
1. Navigate to the Accel-Sim framework directory:
   ```bash
   cd accel-sim-framework
   ```

2. Run the environment setup script:
   ```bash
   . ./environment_setup.sh
   ```

3. Download and install to CUDA 11:
   ```bash
   mkdir -p /tmp/cuda-install

   cd /tmp/cuda-install
   
   wget http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux.run
   
   chmod +x cuda_11.0.1_450.36.06_linux.run
   
   sh cuda_11.0.1_450.36.06_linux.run --toolkit --silent --toolkitpath=$HOME/cuda
   
   cd ~/accel-sim-framework/
   ```
   If the installation fails the first time, run the shell script again (second last step above).

### Step 2: Verify Setup

1. **Check Logs for Errors**:
   Review the `environment_setup_log.txt` file to ensure no errors occurred during the setup:
   ```bash
   cat environment_setup_log.txt
   ```
   Look for any failure messages and address them before proceeding.
   
2. **Check Environment Variables**:
   ```bash
   echo $ACCELSIM_ROOT
   echo $ACCELSIM_CONFIG
   ```
   Ensure they are correctly set (e.g., `$ACCELSIM_ROOT` points to the Accel-Sim framework directory `/root/accel-sim-framework/gpu-simulator`).

3. **Check GPU Simulator Build**:
   ```bash
   ls ./gpu-simulator/bin/release
   ```
   Confirm that the GPU simulator binaries are available in the release directory.

If all these checks pass, your setup is complete.

## Experiment Script

The `experiment.sh` script is designed to run GPU energy optimization experiments using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It automates the process of setting clock frequencies, running simulations, collecting results, and managing trace paths specific to GPU architectures.

### Key Features

1. **Simulation Automation**:
   - Executes simulations using specified benchmarks and GPU core clock configurations.
   - Monitors simulation progress and retrieves performance statistics.

2. **Results Collection**:
   - Collects and organizes results into a structured directory under `./experiment-results`.
   - Saves timing logs for each simulation run.

3. **Results Aggregation**:
   - Aggregates experiment results into consolidated output files using the Python script `data-script.py`.

### Configuring the Experiment

1. **Update the `GPU_CLOCKS` Array**:
   - Define the GPUs and their core clock frequencies for the experiments:
     ```bash
     declare -A GPU_CLOCKS
     GPU_CLOCKS=(
         # Pascal
        ["SM6_TITANX"]="1200.0 1417.0 1620.0 1800.0"
        # Volta
        ["SM7_QV100"]="960.0 1132.0 1455.0 1600.0"
        # Turing
        ["SM75_RTX2060_S"]="1160.0 1365.0 1560.0 2000.0"
     )
     ```

2. **Add Clock Parameters**:
   - Edit the `/root/accel-sim-framework/util/job_launching/configs/define-standard-cfgs.yml` file to include the clock parameters for your experiments:
     ```yaml
     Pascal_1200.0MHZ:
         extra_params: "-gpgpu_clock_domains 1200.0:1200.0:1200.0:2500.0"
     Volta_960.0MHZ:
         extra_params: "-gpgpu_clock_domains 960.0:960.0:960.0:877.0"
     Turing_1160.0MHZ:
         extra_params: "-gpgpu_clock_domains 1160.0:1160.0:1160.0:3500.0"
     ```

3. **Check Trace Paths**:
   - Verify that the trace directories are unzipped and available in `/root/accelwattch_traces/`:
     - Pascal traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_pascal_traces/11.0/`
     - Volta traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_volta_traces/11.0/`
     - Turing traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_turing_traces/11.0/`

### Running the Experiment Script

1. **Navigate to the Accel-Sim Framework Directory**:
   ```bash
   cd accel-sim-framework
   ```

2. **Execute the Experiment Script**:
   ```bash
   ./run_experiments.sh
   ```

### Aggregating Experiment Results

1. **Prepare for Result Aggregation**:
   - Ensure all simulation results are stored in the `experiment-results/` directory.

2. **Run the Aggregation Script**:
   - Use the Python script `data-script.py` to parse and aggregate results:
     ```bash
     python3 experiment-results/data-script.py
     ```

3. **Output of Aggregation**:
   - The script consolidates results into output CSV files stored in their respective subdirectories within `experiment-results/`.

### Experiment Results

- **File Structure**:
  ```
  experiment-results/
  ├── SM6_TITANX-1200.0/
  │   ├── backprop-rodinia-3.1/65536/TITANX-Accelwattch_SASS_SIM/
  │   │   ├── accelwattch_power_report.log
  │   │   └── ...
  │   ├── b+tree-rodinia-3.1/65536/TITANX-Accelwattch_SASS_SIM/
  │   │   ├── accelwattch_power_report.log
  │   │   └── ...
  │   └── SM6_TITANX-1200.0.csv
  │   └── output_SM6_TITANX-1200.0.csv
  └── ...
  ```

- **Log Files**:
  - Timing logs are appended to `./experiment-results/timing.log`.
  - Aggregated results are saved as `output_<subdirectory>.csv`.

- **Verify Aggregation Output**:
   - Ensure the aggregated files include key statistics such as `gpu_avg_TOT_INST`, `gpu_tot_avg_power`, and `gpu_avg_IDLE_COREP`.

### Additional Steps for Result Aggregation

To further process and analyze the results from your experiments, follow these additional steps:

### Step 1: Navigate to the Aggregate Directory
1. Change your working directory to the `aggregate` directory under the `accel-sim-framework`:
   ```bash
   cd accel-sim-framework/aggregate```

### Step 2: Copy CSV Files for the Chip
Copy all the CSV files corresponding to a particular chip (eg. output_SM6_TITANX-1200.0.csv) into the `aggregate` directory. Ensure the files are organized and named appropriately for ease of identification.

### Step 3: Run the Aggregation Script
Execute the aggregation script to combine the results:
```bash
python3 aggregate-script.py```