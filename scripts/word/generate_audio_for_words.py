import json
import subprocess
import os
from pathlib import Path
import sys
import argparse

DEFAULT_VOICE_ID = "a1e12345-1111-4e00-aaaa-000000000001"

def generate_audio(text, phoneme, output_path, voice_id, voice_config_path):
    # Определяем провайдера по voice_id (если есть)
    tts_script = "generate_azure_tts.py"  # по умолчанию
    if voice_id is not None:
        with open(voice_config_path, encoding="utf-8") as vf:
            voices = json.load(vf)
            voice_info = next((v for v in voices if v.get("id") == voice_id), None)
            if voice_info:
                provider = voice_info.get("provider")
                if provider == "azure":
                    tts_script = "./scripts/sound/generate_azure_tts.py"
                elif provider == "aws":
                    tts_script = "./scripts/sound/generate_aws_tts.py"
    command = [sys.executable, tts_script, text, str(output_path)]
    if phoneme:
        command += ["--phoneme", phoneme]
    subprocess.run(command, check=True)

def main(input_path, audio_dir, voice_config, category_filter=None, overwrite=False, single_id=None):
    from copy import deepcopy
    with open(input_path, encoding="utf-8") as f:
        data = json.load(f)
    original_data = deepcopy(data)

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
                voice_entries = [DEFAULT_VOICE_ID]
                entry["voiceEntries"] = voice_entries

            voice_id = voice_entries[0] if version > -1 and voice_entries else DEFAULT_VOICE_ID
            base_path = Path(audio_dir) / category_id
            if version > -1:
                base_path = base_path / word_base / str(version) / str(voice_id)
            base_path.mkdir(parents=True, exist_ok=True)

            # Основное слово
            word_filename = f"{word_base}.mp3"
            word_output_path = base_path / word_filename
            if not word_output_path.exists() or overwrite:
                try:
                    print(f"▶️ Генерация слова: {word_output_path}")
                    generate_audio(word, phoneme, word_output_path, voice_id, voice_config)
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
                        generate_audio(form_text, form_phoneme, form_output_path, voice_id, voice_config)
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
                        generate_audio(example_text, example_phoneme, example_output_path, voice_id, voice_config)
                    except subprocess.CalledProcessError as e:
                        print(f"⚠️ Ошибка генерации примера '{example_text}': {e}")
                else:
                    print(f"✅ Уже существует: {example_output_path}")

    # Обновление только voiceEntries без перезаписи других данных
    for category in data:
        original_category = next((c for c in original_data if c["id"] == category["id"]), None)
        if not original_category:
            continue
        for entry in category.get("entries", []):
            original_entry = next((e for e in original_category.get("entries", []) if e["id"] == entry["id"]), None)
            if original_entry:
                original_entry["voiceEntries"] = entry.get("voiceEntries", [])

    with open(input_path, "w", encoding="utf-8") as f:
        json.dump(original_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate audio for words, forms, and examples.")
    parser.add_argument("--input", required=True, help="Path to the word file")
    parser.add_argument("--audio_dir", required=True, help="Directory to save audio files")
    parser.add_argument("--voice_config", required=True, help="Voice configuration file")
    parser.add_argument("--categories", nargs="*", help="List of category names (by name)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing files")
    parser.add_argument("--id", help="Generate audio only for a specific word by ID")
    args = parser.parse_args()

    main(
        input_path=args.input,
        audio_dir=args.audio_dir,
        voice_config=args.voice_config,
        category_filter=args.categories,
        overwrite=args.overwrite,
        single_id=args.id
    )
