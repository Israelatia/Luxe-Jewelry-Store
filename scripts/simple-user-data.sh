#!/bin/bash
yum update -y
yum install -y docker git java-17
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user
