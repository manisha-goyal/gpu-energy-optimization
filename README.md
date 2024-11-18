# GPU Energy Optimization

This project focuses on optimizing GPU energy consumption using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It explores strategies such as clock frequency adjustments and **Dynamic Voltage and Frequency Scaling (DVFS)** policies to reduce energy usage in computation, memory, and shared memory-intensive programs. The goal is to maintain performance while contributing to sustainable and efficient GPU operations.

## Docker Setup

### Step 1: Download AccelWattch Trace Files
1. Download the AccelWattch trace files from the following link:
   [AccelWattch Trace Files - Google Drive](https://drive.google.com/drive/folders/1gliQrEQhz9ws9UGhHsjdXHZ1Mp2vw8Fj?usp=sharing)

2. Place the downloaded files in the following directory relative to your project root:
   ```
   ./accelwattch_traces
   ```

### Step 2: Build Docker Image
Build the Docker image:
```bash
docker build --platform linux/amd64 -t ubuntu-gcc-cuda .
```

### Step 3: Run Docker Container
Run the container interactively:
```bash
docker run -it ubuntu-gcc-cuda
```

### Step 4: Open Docker Container
If using a remote development environment (e.g., VS Code):
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux).
2. Select **Dev Containers: Attach to Running Container....**.
3. Navigate to the default working directory: `/root`.

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
   Ensure they are correctly set (e.g., `$ACCELSIM_ROOT` points to the Accel-Sim framework directory).

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
   ./experiment.sh
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