# Base image: official Jenkins inbound agent
FROM jenkins/inbound-agent:latest

# Switch to root to install extra tools if needed
USER root

# Example: install Python and Docker CLI
RUN apt-get update && apt-get install -y \
    python3 python3-pip docker.io \
    && rm -rf /var/lib/apt/lists/*

# Switch back to jenkins user
USER jenkins
