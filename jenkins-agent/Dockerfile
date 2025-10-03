FROM jenkins/agent

# Switch to root to install packages
USER root

# Install Python3, pip, curl
RUN apt-get update && apt-get install -y python3 python3-pip curl

# Install Node.js and npm (Node 20 example)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install Snyk CLI
RUN mkdir /snyk && cd /snyk \
    && curl -L https://static.snyk.io/cli/v1.666.0/snyk-linux -o snyk \
    && chmod +x ./snyk \
    && mv ./snyk /usr/local/bin/

# Switch back to Jenkins user
USER jenkins
