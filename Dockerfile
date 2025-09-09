# Use a lightweight Linux image
FROM ubuntu:22.04

# Install basic tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    openjdk-11-jdk \
    maven \
    python3 \
    python3-pip \
    docker.io \
    && apt-get clean

# Set default workdir
WORKDIR /workspace

# Default command
CMD ["sleep", "infinity"]
