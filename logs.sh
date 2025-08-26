#!/bin/bash

# Скрипт для просмотра логов

echo "Available pods:"
kubectl get pods -n donation-app

echo ""
echo "Select component to view logs:"
echo "1. MongoDB"
echo "2. Backend" 
echo "3. Nginx"
echo "4. All"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        kubectl logs -f deployment/donation-mongo -n donation-app
        ;;
    2)
        kubectl logs -f deployment/donation-backend -n donation-app
        ;;
    3)
        kubectl logs -f deployment/donation-nginx -n donation-app
        ;;
    4)
        echo "=== MongoDB Logs ==="
        kubectl logs deployment/donation-mongo -n donation-app --tail=20
        echo ""
        echo "=== Backend Logs ==="
        kubectl logs deployment/donation-backend -n donation-app --tail=20
        echo ""
        echo "=== Nginx Logs ==="
        kubectl logs deployment/donation-nginx -n donation-app --tail=20
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
