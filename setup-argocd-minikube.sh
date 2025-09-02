#!/bin/bash

echo "🚀 Установка ArgoCD в Minikube..."

# Проверка, что Minikube запущен
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube не запущен! Запустите: minikube start"
    exit 1
fi

echo "✅ Minikube запущен"

# 1. Установка ArgoCD
echo "🔄 Установка ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Ожидание готовности ArgoCD..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n argocd

# 2. Настройка доступа к ArgoCD через NodePort
echo "🌐 Настройка доступа к ArgoCD..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":30443}]}}'

# 3. Получение пароля администратора
echo "🔑 Получение пароля администратора ArgoCD..."

PASSWORD=""
ATTEMPTS=0
MAX_ATTEMPTS=15

while [ -z "$PASSWORD" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "Попытка $ATTEMPTS из $MAX_ATTEMPTS..."
    
    # Способ 1: стандартный секрет
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)
    
    if [ -z "$PASSWORD" ]; then
        # Способ 2: секрет argocd-secret
        PASSWORD=$(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.admin\.password}" 2>/dev/null | base64 -d 2>/dev/null)
    fi
    
    if [ -z "$PASSWORD" ]; then
        echo "Ожидание создания секрета... (через 15 секунд)"
        sleep 15
    fi
done

# 4. Получение IP Minikube
MINIKUBE_IP=$(minikube ip)

if [ -n "$PASSWORD" ]; then
    echo ""
    echo "✅ ArgoCD успешно установлен в Minikube!"
    echo "🌐 Доступ: https://$MINIKUBE_IP:30443"
    echo "👤 Логин: admin"
    echo "🔑 Пароль: $PASSWORD"
    echo ""
    echo "📝 Сохраните эти данные для входа в ArgoCD!"
else
    echo "❌ Не удалось получить пароль автоматически."
    echo "Попробуйте получить пароль вручную:"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo ""
    echo "🌐 ArgoCD доступен по адресу: https://$MINIKUBE_IP:30443"
fi

# 5. Установка ArgoCD CLI (опционально)
echo ""
echo "📱 Для установки ArgoCD CLI выполните:"
echo "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "rm argocd-linux-amd64"

echo ""
echo "🎯 Следующие шаги:"
echo "1. Откройте https://$MINIKUBE_IP:30443 в браузере"
echo "2. Войдите с логином 'admin' и полученным паролем"
echo "3. Создайте Application для автоматического развертывания"
