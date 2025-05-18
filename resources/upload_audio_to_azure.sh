#!/bin/bash

# 🔧 Настройки
STORAGE_ACCOUNT_NAME="algaudio"                  # ← ЗАМЕНИ на имя своего хранилища
CONTAINER_NAME="audio"                             # ← имя контейнера
SOURCE_DIR="./audio"                               # ← локальная папка с mp3


MODE="words"
OVERWRITE=false
FILE=""
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --overwrite) OVERWRITE=true ;;
    --mode) MODE="$2"; shift ;;
    --file) FILE="$2"; shift ;;
  esac
  shift
done

# Выбор шаблона поиска в зависимости на режиме
case "$MODE" in
  words)
    PATTERN="[a-f0-9-]*.mp3"
    ;;
  examples)
    PATTERN="*_ex*.mp3"
    ;;
  forms)
    PATTERN="*_form*.mp3"
    ;;
  *)
    echo "⛔ Неизвестный режим: $MODE"
    exit 1
    ;;
esac

# Одинаковая глубина поиска для всех режимов
FIND_DEPTH="-mindepth 2 -maxdepth 2"

# Проверка входа в Azure
echo "▶️ Проверка входа в Azure CLI..."
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "⛔ Не выполнен вход в Azure. Выполни 'az login' перед запуском скрипта."
  exit 1
fi

# Загрузка файлов
echo "🚀 Загружаем mp3-файлы слов в Azure Blob Storage..."

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
  if [ "$MODE" = "words" ]; then
    echo "☑ Переход к пофайловой загрузке для режима 'words'"
    find "$SOURCE_DIR" $FIND_DEPTH -type f -name "*.mp3" | grep -E '/[a-f0-9\-]{36}/[a-f0-9\-]{36}\.mp3$' | while read FILEPATH; do
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
  else
    if [ "$OVERWRITE" = false ]; then
      az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --destination "$CONTAINER_NAME" \
        --source "$SOURCE_DIR" \
        --account-key "$AZURE_STORAGE_KEY" \
        --pattern "$PATTERN" \
        --if-none-match "*"
    else
      az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --destination "$CONTAINER_NAME" \
        --source "$SOURCE_DIR" \
        --account-key "$AZURE_STORAGE_KEY" \
        --pattern "$PATTERN" \
        --overwrite
    fi
  fi
fi
