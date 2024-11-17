# Use an Ubuntu base image
FROM ubuntu:18.04

# Copy the docker build script into the container
COPY docker_build.sh /tmp/docker_build.sh

# Make the docker build script executable
RUN chmod +x /tmp/docker_build.sh

# Run the docker build script during the build
RUN /bin/bash /tmp/docker_build.sh

# Copy run_experiments.sh into the accel-sim-framework directory
COPY run_experiments.sh /root/accel-sim-framework/run_experiments.sh

# Make the run_experiments.sh script executable
RUN chmod +x /root/accel-sim-framework/run_experiments.sh

# Copy the setup script into the container
COPY environment_setup.sh /tmp/environment_setup.sh

# Move the setup script to the accel-sim-framework directory
RUN mv /tmp/environment_setup.sh /root/accel-sim-framework/environment_setup.sh && \
    chmod +x /root/accel-sim-framework/environment_setup.sh

# Copy the AccelWattch Pascal traces
COPY accelwattch_traces/accelwattch_pascal_traces.tgz /root/accelwattch_traces/accelwattch_pascal_traces.tgz

# Unzip the AccelWattch Pascal traces archive
RUN mkdir -p /root/accelwattch_traces && \
    tar -xzf /root/accelwattch_traces/accelwattch_pascal_traces.tgz -C /root/accelwattch_traces && \
    rm /root/accelwattch_traces/accelwattch_pascal_traces.tgz

# Copy the AccelWattch Turing traces
COPY accelwattch_traces/accelwattch_turing_traces.tgz /root/accelwattch_traces/accelwattch_turing_traces.tgz

# Unzip the AccelWattch Turing traces archive
RUN mkdir -p /root/accelwattch_traces && \
    tar -xzf /root/accelwattch_traces/accelwattch_turing_traces.tgz -C /root/accelwattch_traces && \
    rm /root/accelwattch_traces/accelwattch_turing_traces.tgz

# Copy the updated list of apps to run for simulation
COPY define-all-apps.yml /root/accel-sim-framework/util/job_launching/apps/define-all-apps.yml

# Define working directory
WORKDIR /workspace

# Define entrypoint
CMD ["/bin/bash"]