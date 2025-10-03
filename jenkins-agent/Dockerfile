FROM jenkins/agent

# Switch to root to install dependencies
USER root

# Install Python3, pip, Node.js, npm, curl, and Docker CLI
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    curl gnupg lsb-release \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install Snyk CLI
RUN mkdir /snyk && cd /snyk \
    && curl -L https://static.snyk.io/cli/v1.666.0/snyk-linux -o snyk \
    && chmod +x ./snyk \
    && mv ./snyk /usr/local/bin/

# Switch back to Jenkins user
USER jenkins

# Make sure Docker CLI works for Jenkins
ENV DOCKER_HOST=unix:///var/run/docker.sock
