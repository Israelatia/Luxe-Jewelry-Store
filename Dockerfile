FROM jenkins/agent:latest

USER root

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y curl git python3 python3-pip docker.io && \
    curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Verify installs
RUN docker --version
RUN docker-compose --version
RUN python3 --version

USER jenkins


