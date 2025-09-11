# Stage 1: Installer image for AWS CLI and Snyk
FROM amazonlinux:2 as installer

# Install AWS CLI
RUN yum update -y \
 && yum install -y unzip curl \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install --bin-dir /aws-cli-bin/

# Install Snyk
RUN mkdir /snyk && cd /snyk \
 && curl https://static.snyk.io/cli/v1.666.0/snyk-linux -o snyk \
 && chmod +x snyk

# Stage 2: Jenkins agent
FROM jenkins/agent

# Copy Docker client (so we can build images inside Jenkins agent)
COPY --from=docker /usr/local/bin/docker /usr/local/bin/

# Copy AWS CLI and Snyk from installer stage
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer /snyk/ /usr/local/bin/
COPY --from=installer /snyk/ /usr/bin/

USER root

# Install Python if needed
RUN apt-get update && apt-get install -y python3 python3-pip

USER jenkins

