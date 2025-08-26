#!/bin/bash

# Скрипт для развертывания приложения в Minikube

set -e

echo "Deploying Donation App to Minikube..."

# Применяем все конфигурации
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "Deploying MongoDB..."
kubectl apply -f k8s/mongodb-deployment.yaml

echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/donation-mongo -n donation-app

echo "Deploying Backend..."
kubectl apply -f k8s/backend-deployment.yaml

echo "Waiting for Backend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/donation-backend -n donation-app

echo "Deploying Nginx..."
kubectl apply -f k8s/nginx-deployment.yaml

echo "Waiting for Nginx to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/donation-nginx -n donation-app

echo "Getting service information..."
kubectl get services -n donation-app

echo ""
echo "Deployment completed!"
echo ""
echo "To access the application:"
echo "1. Get Minikube IP: minikube ip"
echo "2. Access via: http://<minikube-ip>:30080"
echo ""
echo "To check status:"
echo "kubectl get pods -n donation-app"
echo "kubectl get services -n donation-app"
