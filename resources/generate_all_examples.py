import json
import subprocess
import os
import argparse
from pathlib import Path

# Конфигурация
INPUT_JSON = "./word.json"              # путь к JSON-файлу
AUDIO_DIR_NAME = "audio"                # куда сохранять mp3
TTS_SCRIPT = "generate_tts.py"          # скрипт озвучки

def main(category_filter=None, overwrite=False, single_id=None):
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
            examples = entry.get("examples", [])
            version = entry.get("version", 0)
            voice_entries = entry.get("voiceEntries")

            if version > 0:
                if not voice_entries:
                    print(f"⚠️ Ошибка: отсутствуют voiceEntries у слова {word_base}")
                    continue
                voice_id = voice_entries[0]

            for i, example in enumerate(examples, 1):
                text = example["text"]
                phoneme = example.get("phoneme")
                filename = f"{word_base}_ex{i}.mp3"

                if version == 0:
                    full_dir = Path(AUDIO_DIR_NAME) / category_id
                else:
                    full_dir = Path(AUDIO_DIR_NAME) / category_id / word_base / str(version) / str(voice_id)

                full_dir.mkdir(parents=True, exist_ok=True)
                output_path = full_dir / filename

                if output_path.exists() and not overwrite:
                    print(f"✅ Уже существует: {output_path}")
                    continue

                print(f"▶️ Генерируем: {output_path}")
                try:
                    command = ["/usr/bin/python3", TTS_SCRIPT, text, str(output_path)]
                    if phoneme:
                        command += ["--phoneme", phoneme]
                    subprocess.run(command, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"⚠️ Ошибка генерации для примера \"{text}\": {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация озвучки всех примеров.")
    parser.add_argument("--categories", nargs="*", help="Список названий категорий (по name), если нужно ограничить")
    parser.add_argument("--overwrite", action="store_true", help="Перезаписывать уже существующие файлы")
    parser.add_argument("--id", help="Генерировать озвучку только для конкретного слова по ID")
    args = parser.parse_args()

    main(category_filter=args.categories, overwrite=args.overwrite, single_id=args.id)
