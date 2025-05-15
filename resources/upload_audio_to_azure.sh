#!/bin/bash

# 🔧 Настройки
STORAGE_ACCOUNT_NAME="algaudio"                  # ← ЗАМЕНИ на имя своего хранилища
CONTAINER_NAME="audio"                             # ← имя контейнера
SOURCE_DIR="./audio"                               # ← локальная папка с mp3
PATTERN="*.mp3"

# Проверка входа в Azure
echo "▶️ Проверка входа в Azure CLI..."
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "⛔ Не выполнен вход в Azure. Выполни 'az login' перед запуском скрипта."
  exit 1
fi

# Загрузка файлов
echo "🚀 Загружаем mp3-файлы в Azure Blob Storage..."
if [ -z "$AZURE_STORAGE_KEY" ]; then
  echo "⛔ Переменная окружения AZURE_STORAGE_KEY не установлена."
  exit 1
fi

az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --destination "$CONTAINER_NAME" \
  --source "$SOURCE_DIR" \
  --account-key "$AZURE_STORAGE_KEY" \
  --destination-path "" \
  --if-none-match "*" \
  --pattern "$PATTERN"

if [ $? -eq 0 ]; then
  echo "✅ Загрузка завершена успешно!"
else
  echo "❌ Произошла ошибка при загрузке."
fi
