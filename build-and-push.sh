#!/bin/bash

# Скрипт для сборки и пуша Docker образа бэкенда
# Запускать из корня репозитория donation-app

set -e

echo "Building Docker image for donation-backend..."

# Сборка образа
docker build -t antonshepitko/donation-backend:latest .

echo "Docker image built successfully!"

# Опционально: пуш в Docker Hub (раскомментируйте если нужно)
# echo "Pushing to Docker Hub..."
# docker push antonshepitko/donation-backend:latest
# echo "Image pushed successfully!"

echo "To push to Docker Hub, run:"
echo "docker push antonshepitko/donation-backend:latest"
