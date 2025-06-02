import json
import subprocess
import time
import os
import argparse
from pathlib import Path

# Конфигурация
INPUT_JSON = "./word.json"              # путь к JSON-файлу
OUTPUT_DIR = "audio"                  # куда сохранять mp3
TTS_SCRIPT = "generate_tts.py"        # скрипт озвучки

#MIN_INTERVAL = 3.5 # секунды

def main(category_filter=None, single_id=None, overwrite=False):
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    if single_id:
        data = [category for category in data if any(entry["id"] == single_id for entry in category["entries"])]
        for category in data:
            category["entries"] = [entry for entry in category["entries"] if entry["id"] == single_id]

    for category in data:
        category_id = category["id"]
        category_name = category.get("translations", {}).get("ru") or category.get("translations", {}).get("en") or "Unnamed"

        if category_filter and category_name not in category_filter:
            continue

        for entry in category["entries"]:
            word_base = entry["id"]
            for i, example in enumerate(entry["examples"], 1):
                text = example["text"]
                phoneme = example.get("phoneme")
                filename = f"{word_base}_ex{i}.mp3"
                full_dir = Path(OUTPUT_DIR) / category_id
                full_dir.mkdir(parents=True, exist_ok=True)
                output_path = full_dir / filename

                if output_path.exists() and not overwrite:
                    print(f"✅ Уже существует: {output_path}")
                    continue

                print(f"▶️ Генерируем: {output_path}")
                command = ["/usr/bin/python3", TTS_SCRIPT, text, str(output_path)]
                if phoneme:
                    command += ["--phoneme", phoneme]
                subprocess.run(command)
#                time.sleep(MIN_INTERVAL)  # жёсткое ограничение по rate limit

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация озвучки всех примеров.")
    parser.add_argument("--categories", nargs="*", help="Список названий категорий (по name), если нужно ограничить")
    parser.add_argument("--id", help="ID конкретного слова для генерации")
    parser.add_argument("--overwrite", action="store_true", help="Перезаписать существующие файлы")
    args = parser.parse_args()

    main(category_filter=args.categories, single_id=args.id, overwrite=args.overwrite)
