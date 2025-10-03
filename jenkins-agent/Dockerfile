# Stage 1: install AWS CLI and Snyk
FROM amazonlinux:2 AS installer

RUN yum update -y \
 && yum install -y unzip curl \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install

RUN curl -L https://static.snyk.io/cli/v1.666.0/snyk-linux -o /snyk/snyk \
 && chmod +x /snyk/snyk

# Stage 2: Jenkins agent
FROM jenkins/agent

# Copy AWS CLI and Snyk
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /usr/local/bin/aws /usr/local/bin/
COPY --from=installer /snyk/ /usr/local/bin/

USER root
RUN apt-get update && apt-get install -y python3 python3-pip
USER jenkins

