#!/bin/bash
# Скрипт для настройки ArgoCD на хосте 45.144.52.58

echo "🚀 Настройка ArgoCD хоста..."

# 1. Установка Docker
echo "📦 Установка Docker..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce
sudo usermod -aG docker $USER

# 2. Установка kubectl
echo "⚙️ Установка kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. Установка k3s (легковесный Kubernetes для ArgoCD)
echo "☸️ Установка k3s..."
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 4. Установка ArgoCD
echo "🔄 Установка ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Ожидание готовности ArgoCD..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-dex-server -n argocd

# 5. Настройка доступа к ArgoCD
echo "🌐 Настройка доступа к ArgoCD..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":30443}]}}'

echo "🔑 Получение пароля администратора ArgoCD..."
echo "Попытка получить пароль..."

# Попробуем несколько способов получения пароля
PASSWORD=""
ATTEMPTS=0
MAX_ATTEMPTS=10

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
        # Способ 3: создать пароль вручную
        echo "Создание пароля администратора..."
        NEW_PASSWORD=$(openssl rand -base64 32)
        kubectl -n argocd patch secret argocd-secret -p '{"data":{"admin.password":"'$(echo -n $NEW_PASSWORD | base64)'","admin.passwordMtime":"'$(date +%FT%T%Z | base64)'"}}' 2>/dev/null
        PASSWORD=$NEW_PASSWORD
    fi
    
    if [ -z "$PASSWORD" ]; then
        echo "Ожидание создания секрета... (через 10 секунд)"
        sleep 10
    fi
done

if [ -n "$PASSWORD" ]; then
    echo ""
    echo "✅ ArgoCD Admin Password: $PASSWORD"
    echo ""
    echo "✅ ArgoCD установлен!"
    echo "🌐 Доступ: https://45.144.52.58:30443"
    echo "👤 Логин: admin"
    echo "🔑 Пароль: $PASSWORD"
else
    echo "❌ Не удалось получить пароль автоматически."
    echo "Выполните вручную:"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo "или"
    echo "kubectl -n argocd get secret argocd-secret -o jsonpath=\"{.data.admin\\.password}\" | base64 -d"
fi

# 7. Настройка kubectl для удаленного Minikube
echo ""
echo "🔗 Настройка подключения к удаленному Minikube..."
echo "Выполните на Minikube хосте (45.144.52.219):"
echo "kubectl config view --raw > minikube-config.yaml"
echo "Затем скопируйте файл на этот хост и выполните:"
echo "export KUBECONFIG=/path/to/minikube-config.yaml"

echo ""
echo "📱 Установка ArgoCD CLI (опционально):"
echo "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "rm argocd-linux-amd64"
