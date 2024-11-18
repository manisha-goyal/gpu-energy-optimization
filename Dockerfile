# Use an Ubuntu base image
FROM ubuntu:18.04

# Copy the docker build script into the container
COPY scripts/docker_build.sh /tmp/docker_build.sh

# Make the docker build script executable
RUN chmod +x /tmp/docker_build.sh

# Run the docker build script during the build
RUN /bin/bash /tmp/docker_build.sh

# Copy the setup script into the container
COPY scripts/environment_setup.sh /root/accel-sim-framework/environment_setup.sh

# Make the environment_setup.sh script executable
RUN chmod +x /root/accel-sim-framework/environment_setup.sh

# Copy run_experiments.sh into the accel-sim-framework directory
COPY scripts/run_experiments.sh /root/accel-sim-framework/run_experiments.sh

# Make the run_experiments.sh script executable
RUN chmod +x /root/accel-sim-framework/run_experiments.sh

# Copy the AccelWattch traces into the container
COPY accelwattch_traces /root/accel-sim-framework/accelwattch_traces

# Copy the GPU Simulator Apps config files into the container
COPY configs/define-all-apps.yml /root/accel-sim-framework/util/job_launching/apps/define-all-apps.yml
COPY configs/define-standard-cfgs.yml /root/accel-sim-framework/util/job_launching/configs/define-standard-cfgs.yml

# Define working directory
WORKDIR /root/accel-sim-framework

# Define entrypoint
CMD ["/bin/bash"]