# Use official Python image as base
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Switch to root to install dependencies
USER root

# Install required system packages
RUN apt-get update && apt-get install -y \
    curl \
    docker.io \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Copy backend code
COPY backend/ .

# Install Python dependencies
RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt

# Install Snyk CLI
RUN curl -L https://static.snyk.io/cli/v1.666.0/snyk-linux -o /usr/local/bin/snyk \
    && chmod +x /usr/local/bin/snyk

# Make sure Docker CLI works inside container
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Set PATH to include virtual environment
ENV PATH="/app/venv/bin:$PATH"

# Switch back to a non-root user
USER 1000

# Default command
CMD ["python3", "main.py"]
