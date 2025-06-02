import json
import subprocess
import os
import argparse
from pathlib import Path

# Конфигурация
INPUT_JSON = "./word.json"              # путь к JSON-файлу
OUTPUT_DIR = "audio"                  # куда сохранять mp3
TTS_SCRIPT = "generate_tts.py"        # скрипт озвучки


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
            for index, form in enumerate(entry.get("forms", [])):
                form_text = form["form"]
                phoneme = form.get("phoneme")
                filename = f"{word_base}_form{index + 1}.mp3"
                full_dir = Path(OUTPUT_DIR) / category_id
                full_dir.mkdir(parents=True, exist_ok=True)
                output_path = full_dir / filename

                if output_path.exists() and not overwrite:
                    print(f"⏩ Skipped (already exists): {output_path.name}")
                    continue

                print(f"🔊 Generating form audio: {form_text} → {output_path.name}")
                try:
                    command = ["/usr/bin/python3", TTS_SCRIPT, form_text, str(output_path)]
                    if phoneme:
                        command += ["--phoneme", phoneme]
                    subprocess.run(command, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"❌ Failed to generate audio for form '{form_text}' → {output_path.name}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate audio for all word forms.")
    parser.add_argument("--categories", nargs="*", help="List of category names to limit generation (optional)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing files if they already exist")
    parser.add_argument("--id", help="Generate audio only for entry with this id")
    args = parser.parse_args()

    main(category_filter=args.categories, overwrite=args.overwrite, single_id=args.id)
