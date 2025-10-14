FROM jenkins/agent:latest

# Switch to root to install dependencies
USER root

# Install Python3, pip, curl, gnupg, lsb-release, and Docker CLI
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    curl gnupg lsb-release \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------
# Option 1: Snyk binary (your current method)
# ----------------------------
RUN mkdir /snyk && cd /snyk \
    && curl -L https://static.snyk.io/cli/v1.666.0/snyk-linux -o snyk \
    && chmod +x ./snyk \
    && mv ./snyk /usr/local/bin/

# ----------------------------
# Option 2: Snyk via npm (if you want the latest version)
# ----------------------------
# Install Node.js + npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g snyk

# Make sure Docker CLI works for Jenkins
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Switch back to Jenkins user
USER jenkins