# GPU Energy Optimization

This project focuses on optimizing GPU energy consumption using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It explores strategies such as clock frequency adjustments to reduce energy usage in computation, memory, and shared memory-intensive programs. The goal is to maintain performance while contributing to sustainable and efficient GPU operations.

## Singularity Setup (Using docker image)

### Step 1: Login to the HPC cuda cluster (any cuda machine)
```bash
ssh cuda4
```

### Step 2: Create a working directory in scratch
**Note:** Incase, `mkdir` gives directory always exists error, please chose any available directory name and `cd` into that
```bash
cd /scratch/
mkdir fa24-gpu-project-group29-energy-consumption
cd fa24-gpu-project-group29-energy-consumption
```

### Step 3: Change Singularity cache directory
```bash
export SINGULARITY_CACHEDIR=$(pwd)
source ~/.bashrc
```

### Step 4: Pull and Build our Docker Image
```bash
singularity pull docker://akubal/fa24-gpu-project-g29
singularity build --sandbox extracted_container fa24-gpu-project-g29_latest.sif
```

### Step 5: Start singularity container
```bash
singularity exec --writable --no-home --cleanenv extracted_container /bin/bash --rcfile /root/.bashrc
```

### Step 6: Change `HOME` dir
```bash
export HOME=/root
```

## Experiment Setup

### Instructions
1. Navigate to the Accel-Sim framework directory:
   ```bash
   cd /root/accel-sim-framework
   ```

2. Run the environment setup script:
   **Note:** There is a **`<dot>`** before the executable, it is **`<dot><space><dot>/environment_setup.sh`**. Please do not miss the first dot, it will cause errors.
   ```bash
   . ./environment_setup.sh
   ```

3. Download and install CUDA 11 (CUDA installation step might take some time with no output printed):
   ```bash
   cd /root

   mv cuda cuda_old

   mkdir cuda 

   mkdir -p /root/cuda-install

   cd /root/cuda-install
   
   wget http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux.run
   
   chmod +x cuda_11.0.1_450.36.06_linux.run
   
   ./cuda_11.0.1_450.36.06_linux.run --toolkit --silent --toolkitpath=$HOME/cuda
   
   cd /root/accel-sim-framework/
   ```
   If the installation fails the first time, run the shell script again (second last step above).

### Some helpful debugging step, incase of any errors

1. **Check logs for errors**:
   Review the `environment_setup_log.txt` file to ensure no errors occurred during the setup:
   ```bash
   cat environment_setup_log.txt
   ```
   Look for any failure messages and address them before proceeding.
   
2. **Check environment variables**:
   Ensure the following env variables correctly set as shown below
   ```bash
   echo $ACCELSIM_ROOT
   >>> "/root/accel-sim-framework/gpu-simulator"
   echo $ACCELSIM_CONFIG
   >>> "release"
   ```

3. **Check GPU simulator build**:
   Confirm that the GPU simulator binaries are available in the release directory.
   ```bash
   ls /root/accel-sim-framework/gpu-simulator/bin/release
   >>> "accel-sim.out"
   ```
   

If all these checks pass, your setup is complete.

## Run Experiment

1. **Navigate to the Accel-Sim framework directory**:
   ```bash
   cd /root/accel-sim-framework
   ```

2. **Execute the experiment script**:
   ```bash
   ./run_experiments.sh
   ```

## Genrating Experiment Results

1. **Check all experiments results are generated**:
   Ensure all simulation results are stored in the `experiment-results/` directory.
   ```bash
   ls /root/accel-sim-framework/experiment-results/
   >>> experiment-results/
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

2. **Run the aggregation script**:
   - Use the Python script `data-script.py` to parse and aggregate results:
     ```bash
     python3 /root/accel-sim-framework/experiment-results/data-script.py
     ```
   
   - The script consolidates results into output CSV files stored in their respective subdirectories within `experiment-results/` as saved as `output_<subdirectory>.csv`. In this case **`output_SM6_TITANX-1200.0.csv`**
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

   - **Verify aggregation output**:
      - Read any of the aggregated files, and verify that it includes key statistics such as `gpu_avg_TOT_INST`, `gpu_tot_avg_power`, and `gpu_avg_IDLE_COREP`.

## Understanding Experiment Results

To further process and analyze the results from your experiments, follow these additional steps:

1. **Navigate to the aggregate directory**
Change your working directory to the `aggregate` directory under the `accel-sim-framework`:
   ```bash
   cd accel-sim-framework/aggregate
   ```

2. **Copy CSV files for the chip**
Copy all the CSV files corresponding to a particular chip `output_<chip_name>-<freq>.0.csv` (eg. `output_SM6_TITANX-1200.0.csv`) into the `aggregate` directory.
   ```bash
   mv experiment-results/SM6_TITANX-1100.0/output_SM6_TITANX-1100.0.csv accel-sim-framework/aggregate/

   mv experiment-results/SM6_TITANX-1200.0/output_SM6_TITANX-1200.0.csv accel-sim-framework/aggregate/

   mv experiment-results/SM6_TITANX-1417.0/output_SM6_TITANX-1417.0.csv accel-sim-framework/aggregate/

   mv experiment-results/SM6_TITANX-1620.0/output_SM6_TITANX-1620.0.csv accel-sim-framework/aggregate/

   mv experiment-results/SM6_TITANX-1800.0/output_SM6_TITANX-1800.0.csv accel-sim-framework/aggregate/
   ```

3. **Run the aggregation script**
   - Execute the aggregation script to combine the results:
     ```bash
     python3 aggregate-script.py
     ```
   
   - The script consolidates results for the GPU chip across frequencies into an output CSV file stored in the `aggregate` directory as saved as `<chip_name>.csv`. In this case **`SM6_TITANX.csv`**
     ```
      aggregate/
      ├── SM6_TITANX.csv
      ```

## Additional Details for Tinkering Around

The `run_experiments.sh` script is designed to run GPU energy optimization experiments using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It automates the process of setting clock frequencies, running simulations, collecting results, and managing trace paths specific to GPU architectures.

### Key Features

1. **Simulation automation**:
   - Executes simulations using specified benchmarks and GPU core clock configurations.
   - Monitors simulation progress and retrieves performance statistics.

2. **Results collection**:
   - Collects and organizes results into a structured directory under `./experiment-results`.
   - Saves timing logs for each simulation run.

### Manually configuring the experiment

1. **Update the `GPU_CLOCKS` array**:
   - Define the GPUs and their core clock frequencies for the experiments (if different from the default):
     ```bash
     declare -A GPU_CLOCKS
     GPU_CLOCKS=(
         # Pascal
         ["SM6_TITANX"]="1000.0 1200.0 1417.0 1620.0 1800.0"
         # Volta
         ["SM7_QV100"]="760.0 960.0 1132.0 1455.0 1600.0"
         # Turing
         ["SM75_RTX2060_S"]="1160.0 1365.0 1470.0 1700.0 1960.0"
     )
     ```

2. **Add clock parameters**:
   - Edit the `/root/accel-sim-framework/util/job_launching/configs/define-standard-cfgs.yml` file to include the clock parameters for your experiments (if different from the default):
     ```yaml
     Pascal_1200.0MHZ:
         extra_params: "-gpgpu_clock_domains 1200.0:1200.0:1200.0:2500.0"
     Volta_960.0MHZ:
         extra_params: "-gpgpu_clock_domains 960.0:960.0:960.0:877.0"
     Turing_1160.0MHZ:
         extra_params: "-gpgpu_clock_domains 1160.0:1160.0:1160.0:3500.0"
     ```

3. **Accel-Wattch trace paths**:
   - The accel-wattch trace files are available in `/root/accelwattch_traces/`:
     - Pascal traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_pascal_traces/11.0/`
     - Volta traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_volta_traces/11.0/`
     - Turing traces: `/root/accel-sim-framework/accelwattch_traces/accelwattch_turing_traces/11.0/`