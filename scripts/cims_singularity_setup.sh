# Enter scratch and create working dir
cd /scratch/
mkdir fa24-gpu-project-group29-energy-consumption
cd fa24-gpu-project-group29-energy-consumption

# Change Singularity cache dir
export SINGULARITY_CACHEDIR=$(pwd)
source ~/.bashrc

# Pull and Build Docker Image 
singularity pull docker://akubal/ubuntu-gcc-cuda
singularity build --sandbox extracted_container ubuntu-gcc-cuda_latest.sif

# Run singularity
singularity exec --writable --no-home --cleanenv extracted_container /bin/bash --rcfile /root/.bashrc

# Enter root
cd /root/
