import json
import subprocess
import time
import os
import argparse
from pathlib import Path

# Конфигурация
INPUT_JSON = "../Alg/Data/word.json"              # путь к JSON-файлу
OUTPUT_DIR = "audio"                  # куда сохранять mp3
TTS_SCRIPT = "generate_tts.py"        # скрипт озвучки

#MIN_INTERVAL = 3.5 # секунды

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
            for i, example in enumerate(entry["examples"], 1):
                # hash_part = hash_example(example)
                filename = f"{word_base}_ex{i}.mp3"
                full_dir = Path(OUTPUT_DIR) / category_id
                full_dir.mkdir(parents=True, exist_ok=True)
                output_path = full_dir / filename

                if output_path.exists():
                    print(f"✅ Уже существует: {output_path}")
                    continue

                print(f"▶️ Генерируем: {output_path}")
                subprocess.run([
                    "/usr/bin/python3", TTS_SCRIPT,
                    example,
                    str(output_path)
                ])
#                time.sleep(MIN_INTERVAL)  # жёсткое ограничение по rate limit

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация озвучки всех примеров.")
    parser.add_argument("--categories", nargs="*", help="Список названий категорий (по name), если нужно ограничить")
    args = parser.parse_args()

    main(category_filter=args.categories)
