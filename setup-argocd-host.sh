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

# 5. Настройка доступа к ArgoCD
echo "🌐 Настройка доступа к ArgoCD..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8080,"nodePort":30443}]}}'

# 6. Получение пароля администратора
echo "🔑 Получение пароля администратора ArgoCD..."
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "✅ ArgoCD установлен!"
echo "🌐 Доступ: https://45.144.52.58:30443"
echo "👤 Логин: admin"
echo "🔑 Пароль: см. выше"

# 7. Настройка kubectl для удаленного Minikube
echo "🔗 Настройка подключения к удаленному Minikube..."
echo "Выполните на Minikube хосте (45.144.52.219):"
echo "kubectl config view --raw > minikube-config.yaml"
echo "Затем скопируйте файл на этот хост и выполните:"
echo "export KUBECONFIG=/path/to/minikube-config.yaml"
