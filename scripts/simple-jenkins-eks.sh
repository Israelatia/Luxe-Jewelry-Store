#!/bin/bash
# Simple Jenkins to EKS

kubectl create namespace israel-jenkins
kubectl create namespace israel-app
kubectl create namespace israel-argo

kubectl apply -f k8s/ -n israel-jenkins

echo "Jenkins deployed to EKS"
