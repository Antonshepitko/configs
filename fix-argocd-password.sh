#!/bin/bash
# Скрипт для исправления проблемы с паролем ArgoCD

echo "🔧 Исправление пароля ArgoCD..."

# Проверяем статус подов ArgoCD
echo "📊 Статус подов ArgoCD:"
kubectl get pods -n argocd

echo ""
echo "🔑 Попытка получить пароль несколькими способами..."

# Способ 1: Стандартный секрет
echo "Способ 1: argocd-initial-admin-secret"
PASSWORD1=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)
if [ -n "$PASSWORD1" ]; then
    echo "✅ Пароль найден: $PASSWORD1"
    exit 0
fi

# Способ 2: Секрет argocd-secret
echo "Способ 2: argocd-secret"
PASSWORD2=$(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.admin\.password}" 2>/dev/null | base64 -d 2>/dev/null)
if [ -n "$PASSWORD2" ]; then
    echo "✅ Пароль найден: $PASSWORD2"
    exit 0
fi

# Способ 3: Сброс пароля
echo "Способ 3: Сброс пароля администратора"
NEW_PASSWORD=$(openssl rand -base64 16)
BCRYPT_PASSWORD=$(htpasswd -bnBC 10 "" $NEW_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')

kubectl -n argocd patch secret argocd-secret \
  -p '{"data":{"admin.password":"'$(echo -n $BCRYPT_PASSWORD | base64)'","admin.passwordMtime":"'$(date +%FT%T%Z | base64)'"}}' 

echo "✅ Новый пароль установлен: $NEW_PASSWORD"
echo ""
echo "🔄 Перезапуск ArgoCD сервера..."
kubectl -n argocd rollout restart deployment argocd-server

echo "⏳ Ожидание готовности сервера..."
kubectl -n argocd rollout status deployment argocd-server

echo ""
echo "✅ Готово!"
echo "🌐 Доступ: https://45.144.52.58:30443"
echo "👤 Логин: admin"
echo "🔑 Пароль: $NEW_PASSWORD"
