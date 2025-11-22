#!/bin/bash
# Simple Secrets Manager setup

aws secretsmanager create-secret \
  --name luxe-db-credentials \
  --secret-string '{"username":"admin","password":"password123"}'

echo "Secret created in Secrets Manager"
