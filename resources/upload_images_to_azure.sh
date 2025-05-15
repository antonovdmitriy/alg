#!/bin/bash

# 🔧 Configuration
STORAGE_ACCOUNT_NAME="algaudio"                  # ← replace with your storage account name
CONTAINER_NAME="images"                             # ← container name
SOURCE_DIR="./images"                               # ← local folder with images
PATTERN="*.png"

# Check Azure login
echo "▶️ Checking Azure CLI login..."
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "⛔ Not logged into Azure. Run 'az login' before running the script."
  exit 1
fi

# Upload files
echo "🚀 Uploading images to Azure Blob Storage..."
if [ -z "$AZURE_STORAGE_KEY" ]; then
  echo "⛔ Environment variable AZURE_STORAGE_KEY is not set."
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
  echo "✅ Upload completed successfully!"
else
  echo "❌ An error occurred during upload."
fi
