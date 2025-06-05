import json
import subprocess
import os
import argparse
from pathlib import Path
import sys

# Конфигурация
INPUT_JSON = "./word.json"
AUDIO_DIR_NAME = "audio"
VOICE_CONFIG_PATH = "voice.json"
def generate_audio(text, phoneme, output_path, voice_id):
    # Определяем провайдера по voice_id (если есть)
    tts_script = "generate_azure_tts.py"  # по умолчанию
    if voice_id is not None:
        with open(VOICE_CONFIG_PATH, encoding="utf-8") as vf:
            voices = json.load(vf)
            voice_info = next((v for v in voices if v.get("id") == voice_id), None)
            if voice_info:
                provider = voice_info.get("provider")
                if provider == "azure":
                    tts_script = "generate_azure_tts.py"
                elif provider == "aws":
                    tts_script = "generate_aws_tts.py"
    command = [sys.executable, tts_script, text, str(output_path)]
    if phoneme:
        command += ["--phoneme", phoneme]
    subprocess.run(command, check=True)

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
            word = entry["word"]
            phoneme = entry.get("phoneme")
            version = entry.get("version", -1)
            voice_entries = entry.get("voiceEntries")

            if version > -1 and not voice_entries:
                print(f"⚠️ Ошибка: отсутствуют voiceEntries у слова {word_base}")
                continue

            voice_id = voice_entries[0] if version > -1 else None
            base_path = Path(AUDIO_DIR_NAME) / category_id
            if version > -1:
                base_path = base_path / word_base / str(version) / str(voice_id)
            base_path.mkdir(parents=True, exist_ok=True)

            # Основное слово
            word_filename = f"{word_base}.mp3"
            word_output_path = base_path / word_filename
            if not word_output_path.exists() or overwrite:
                try:
                    print(f"▶️ Генерация слова: {word_output_path}")
                    generate_audio(word, phoneme, word_output_path, voice_id)
                except subprocess.CalledProcessError as e:
                    print(f"⚠️ Ошибка генерации для слова '{word}': {e}")
            else:
                print(f"✅ Уже существует: {word_output_path}")

            # Формы
            for index, form in enumerate(entry.get("forms", [])):
                form_text = form["form"]
                form_phoneme = form.get("phoneme")
                form_filename = f"{word_base}_form{index + 1}.mp3"
                form_output_path = base_path / form_filename
                if not form_output_path.exists() or overwrite:
                    try:
                        print(f"▶️ Генерация формы: {form_output_path}")
                        generate_audio(form_text, form_phoneme, form_output_path, voice_id)
                    except subprocess.CalledProcessError as e:
                        print(f"⚠️ Ошибка генерации формы '{form_text}': {e}")
                else:
                    print(f"✅ Уже существует: {form_output_path}")

            # Примеры
            for index, example in enumerate(entry.get("examples", [])):
                example_text = example["text"]
                example_phoneme = example.get("phoneme")
                example_filename = f"{word_base}_ex{index + 1}.mp3"
                example_output_path = base_path / example_filename
                if not example_output_path.exists() or overwrite:
                    try:
                        print(f"▶️ Генерация примера: {example_output_path}")
                        generate_audio(example_text, example_phoneme, example_output_path, voice_id)
                    except subprocess.CalledProcessError as e:
                        print(f"⚠️ Ошибка генерации примера '{example_text}': {e}")
                else:
                    print(f"✅ Уже существует: {example_output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Генерация озвучки слов, форм и примеров.")
    parser.add_argument("--categories", nargs="*", help="Список названий категорий (по name)")
    parser.add_argument("--overwrite", action="store_true", help="Перезаписывать существующие файлы")
    parser.add_argument("--id", help="Генерация озвучки только для конкретного слова по ID")
    args = parser.parse_args()

    main(category_filter=args.categories, overwrite=args.overwrite, single_id=args.id)
