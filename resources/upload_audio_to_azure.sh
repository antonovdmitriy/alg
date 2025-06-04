#!/bin/bash

# 🔧 Настройки
STORAGE_ACCOUNT_NAME="algaudio"                  # ← ЗАМЕНИ на имя своего хранилища
CONTAINER_NAME="audio"                             # ← имя контейнера
SOURCE_DIR="./audio"                               # ← локальная папка с mp3


OVERWRITE=false
FILE=""
WORD_ID=""
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --overwrite) OVERWRITE=true ;;
    --file) FILE="$2"; shift ;;
    --id) WORD_ID="$2"; shift ;;
  esac
  shift
done

if [ -n "$WORD_ID" ]; then
  echo "🔎 Ищем mp3-файлы для слова с id=$WORD_ID..."
  FILE_LIST=$(find "$SOURCE_DIR" -type f -path "*/$WORD_ID/*" -name "*.mp3")
  if [ -z "$FILE_LIST" ]; then
    echo "⚠️  Не найдено файлов для id=$WORD_ID"
    exit 0
  fi
  for FILEPATH in $FILE_LIST; do
    BLOB_PATH="${FILEPATH#./audio/}"
    if [ "$OVERWRITE" = false ]; then
      az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$CONTAINER_NAME" \
        --file "$FILEPATH" \
        --name "$BLOB_PATH" \
        --account-key "$AZURE_STORAGE_KEY" \
        --if-none-match "*" > /dev/null
    else
      az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$CONTAINER_NAME" \
        --file "$FILEPATH" \
        --name "$BLOB_PATH" \
        --account-key "$AZURE_STORAGE_KEY" \
        --overwrite > /dev/null
    fi

    if [ $? -eq 0 ]; then
      echo "✅ $BLOB_PATH загружен"
    else
      echo "⚠️  Ошибка загрузки $BLOB_PATH"
    fi
  done
  exit 0
fi

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

if [ -n "$FILE" ]; then
  az storage blob upload \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$CONTAINER_NAME" \
    --file "$FILE" \
    --name "${FILE#./audio/}" \
    --account-key "$AZURE_STORAGE_KEY" \
    $( [ "$OVERWRITE" = false ] && echo "--if-none-match \"*\"" || echo "--overwrite" ) > /dev/null

  if [ $? -eq 0 ]; then
    echo "✅ ${FILE#./audio/} загружен"
  else
    echo "⚠️  Ошибка загрузки ${FILE#./audio/}"
  fi
else
  find "$SOURCE_DIR" -type f -name "*.mp3" | grep -E '/[a-f0-9\-]{36}(/|/[^/]+/[^/]+/[^/]+/).*\.mp3$' | while read FILEPATH; do
    BLOB_PATH="${FILEPATH#./audio/}"
    if [ "$OVERWRITE" = false ]; then
      az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$CONTAINER_NAME" \
        --file "$FILEPATH" \
        --name "$BLOB_PATH" \
        --account-key "$AZURE_STORAGE_KEY" \
        --if-none-match "*" > /dev/null
    else
      az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$CONTAINER_NAME" \
        --file "$FILEPATH" \
        --name "$BLOB_PATH" \
        --account-key "$AZURE_STORAGE_KEY" \
        --overwrite > /dev/null
    fi

    if [ $? -eq 0 ]; then
      echo "✅ $BLOB_PATH загружен"
    else
      echo "⚠️  Ошибка загрузки $BLOB_PATH"
    fi
  done
fi
