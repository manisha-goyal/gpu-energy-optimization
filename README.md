# GPU Energy Optimization

This project focuses on optimizing GPU energy consumption using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It explores strategies such as clock frequency adjustments and **Dynamic Voltage and Frequency Scaling (DVFS)** policies to reduce energy usage in computation, memory, and shared memory-intensive programs. The goal is to maintain performance while contributing to sustainable and efficient GPU operations.

---

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

### Open Docker Container (Optional)
If using a remote development environment (e.g., VS Code):
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux).
2. Select **Dev Containers: Attach to Running Container....**.
3. Navigate to the default working directory: `/root`.

---

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

---

## Experiment Script

The `experiment.sh` script is designed to run GPU energy optimization experiments using **Accel-Sim**, **AccelWattch**, and **GPGPU-Sim**. It automates the process of setting clock frequencies, running simulations, and collecting results.

### Key Features

1. **GPU Clock Frequency Configuration**:
   - The `GPU_CLOCKS` associative array maps GPUs to their respective clock frequencies. Update this array to configure the experiment parameters.

   Example:
   ```bash
   declare -A GPU_CLOCKS
   GPU_CLOCKS=(
       ["SM7_QV100"]="1132.0 1832.0"
       ["SM7_TITANV"]="1200.0 1800.0"
   )
   ```

2. **Simulation Automation**:
   - Updates GPU clock configurations dynamically in the `gpugpusim.config` file.
   - Runs simulations using specified benchmarks.
   - Monitors simulation progress and retrieves performance statistics.

3. **Results Collection**:
   - Collects results into a structured directory under `./experiment-results`.
   - Saves timing logs for each simulation.

### Running the Script

1. Navigate to the Accel-Sim framework directory:
   ```bash
   cd accel-sim-framework
   ```

2. Run the experiment script:
   ```bash
   ./experiment.sh
   ```

### Configuring the Experiment

Before running the script:
1. **Update the `GPU_CLOCKS` array**:
   - Specify the GPUs and their corresponding clock frequencies for your experiments.

2. **Set the Memory Clock Frequency**:
   - Modify the `MEMORY_CLOCK` variable in the script to configure the memory clock (default is `850.0 MHz`):
     ```bash
     MEMORY_CLOCK=850.0
     ```

3. **Verify Configurations**:
   - Ensure the `gpugpusim.config` files exist under `./gpu-simulator/gpgpu-sim/configs/tested-cfgs` for each GPU listed in the `GPU_CLOCKS` array.

### Experiment Results

- Results are stored in the `./experiment-results` directory in a structured format:
  ```
  experiment-results/
  ├── SM7_QV100-1132.0/
  │   ├── backprop/
  │   │   ├── QV100-Accelwattch_PTX_SIM/
  │   │   ├── stats.csv
  │   │   └── ...
  │   └── timing.log
  └── ...
  ```

- Timing logs are appended to `./experiment-results/timing.log`.