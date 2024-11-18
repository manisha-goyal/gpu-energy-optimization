# GPU Energy Optimization

This project focuses on optimizing GPU energy consumption using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It explores strategies such as clock frequency adjustments and **Dynamic Voltage and Frequency Scaling (DVFS)** policies to reduce energy usage in computation, memory, and shared memory-intensive programs. The goal is to maintain performance while contributing to sustainable and efficient GPU operations.

## Docker Setup

### Build Docker Image
Build the Docker image:
```bash
docker build --platform linux/amd64 -t ubuntu-gcc-cuda .
```

### Run Docker Container
Run the container interactively:
```bash
docker run -it ubuntu-gcc-cuda
```

### Open Docker Container
If using a remote development environment (e.g., VS Code):
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux).
2. Select **Dev Containers: Attach to Running Container....**.
3. Navigate to the default working directory: `/root`.

## Accel-Sim Setup

### Setup Environment
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
   
   bash cuda_11.0.1_450.36.06_linux.run --toolkit --silent --toolkitpath=$HOME/cuda
   
   cd ~/accel-sim-framework/
   ```

### Verify Setup

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
   - Runs simulations using specified benchmarks and GPU core clock configurations.
   - Monitors simulation progress and retrieves performance statistics.

2. **Results Collection**:
   - Collects results into a structured directory under `./experiment-results`.
   - Saves timing logs for each simulation.

### Configuring the Experiment

Before running the script:

1. **Update the `GPU_CLOCKS` Array**:
   - Specify the core clock frequencies for your experiments.

   Example:
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
   - Update the `/root/accel-sim-framework/util/job_launching/configs/define-standard-cfgs.yml` file to include clock parameters for your experiments if different from the default. Use the following format:
     ```yaml
     Pascal_1200.0MHZ:
         extra_params: "-gpgpu_clock_domains 1200.0:1200.0:1200.0:2500.0"
     Volta_960.0MHZ:
         extra_params: "-gpgpu_clock_domains 960.0:960.0:960.0:877.0"
     Turing_1160.0MHZ:
         extra_params: "-gpgpu_clock_domains 1160.0:1160.0:1160.0:3500.0"
     ```

3. **Check Trace Paths**:
   - Ensure the trace directories are unzipped and available under `/root/accelwattch_traces/`:
     - Pascal traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_pascal_traces/11.0/`
     - Volta traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_volta_traces/11.0/`
     - Turing traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_turing_traces/11.0/`

### Running the Script

1. Navigate to the Accel-Sim framework directory:
   ```bash
   cd accel-sim-framework
   ```

2. Run the experiment script:
   ```bash
   ./experiment.sh
   ```

### Experiment Results

- Results are stored in the `./experiment-results` directory in a structured format:
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
  └── ...
  ```

- Timing logs for the experiment are appended to `./experiment-results/timing.log`.
---