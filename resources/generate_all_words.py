import json
import subprocess
import os
import argparse
from pathlib import Path

# Конфигурация
INPUT_JSON = "../Alg/Data/word.json"              # путь к JSON-файлу
OUTPUT_DIR = "audio"                  # куда сохранять mp3
TTS_SCRIPT = "generate_tts.py"        # скрипт озвучки


def main(category_filter=None):
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    for category in data:
        category_id = category["id"]
        category_name = category["name"]

        if category_filter and category_name not in category_filter:
            continue

        for entry in category["entries"]:
            word_base = entry["id"]
            word = entry["word"]
            filename = f"{word_base}.mp3"
            full_dir = Path(OUTPUT_DIR) / category_id
            full_dir.mkdir(parents=True, exist_ok=True)
            output_path = full_dir / filename

            if output_path.exists():
                print(f"✅ Уже существует: {output_path}")
                continue

            print(f"▶️ Генерируем: {output_path}")
            try:
                subprocess.run([
                    "/usr/bin/python3", TTS_SCRIPT,
                    word,
                    str(output_path)
                ], check=True)
            except subprocess.CalledProcessError as e:
                print(f"⚠️ Ошибка генерации для {word}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация озвучки всех слов.")
    parser.add_argument("--categories", nargs="*", help="Список названий категорий (по name), если нужно ограничить")
    args = parser.parse_args()

    main(category_filter=args.categories)
