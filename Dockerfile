# Use an Ubuntu base image
FROM ubuntu:18.04


# Copy the script into the container
COPY script.sh /tmp/script.sh

# Make the script executable
RUN chmod +x /tmp/script.sh

# Run the script during the build
RUN /bin/bash /tmp/script.sh

# Define working directory
WORKDIR /workspace

# Define entrypoint
CMD ["/bin/bash"]
