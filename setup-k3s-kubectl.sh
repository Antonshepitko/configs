#!/bin/bash
# Скрипт для настройки kubectl для работы с k3s

echo "🔧 Настройка kubectl для k3s..."

# Проверяем, что k3s установлен
if ! command -v k3s &> /dev/null; then
    echo "❌ k3s не найден. Устанавливаем k3s..."
    curl -sfL https://get.k3s.io | sh -
    systemctl enable k3s
    systemctl start k3s
fi

# Настраиваем KUBECONFIG
echo "📝 Настройка KUBECONFIG..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Добавляем в bashrc для постоянного использования
if ! grep -q "KUBECONFIG=/etc/rancher/k3s/k3s.yaml" ~/.bashrc; then
    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
fi

# Устанавливаем права доступа
chmod 644 /etc/rancher/k3s/k3s.yaml

# Проверяем подключение
echo "🔍 Проверка подключения к кластеру..."
kubectl cluster-info

echo "📊 Статус узлов:"
kubectl get nodes

echo "✅ kubectl настроен для работы с k3s!"
