#!/bin/bash

# Скрипт для удаления всех ресурсов

set -e

echo "Cleaning up Donation App resources..."

kubectl delete namespace donation-app --ignore-not-found=true

echo "Cleanup completed!"
