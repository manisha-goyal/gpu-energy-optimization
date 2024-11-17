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