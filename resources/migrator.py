import os
import json
import collections

def merge_translation_files(output_file="word_translated.json"):
    with open("word.json", "r", encoding="utf-8") as f:
        original_data = json.load(f)
        original_order = [cat["id"] for cat in original_data]

    translated_map = {}
    for root, dirs, files in os.walk('.'):
        for filename in files:
            if filename.startswith("translated_") and filename.endswith(".json"):
                filepath = os.path.join(root, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        if isinstance(data, dict) and "id" in data and "entries" in data:
                            translated_map[data["id"]] = data
                        elif isinstance(data, list):
                            for cat in data:
                                if "id" in cat:
                                    translated_map[cat["id"]] = cat
                        else:
                            print(f"⚠️ Файл {filepath} не содержит допустимый формат.")
                except Exception as e:
                    print(f"❌ Ошибка при чтении {filepath}: {e}")

    merged = [translated_map[cat_id] for cat_id in original_order if cat_id in translated_map]

    with open(output_file, "w", encoding="utf-8") as out_f:
        json.dump(merged, out_f, ensure_ascii=False, indent=2)
    print(f"✅ Объединённый файл сохранён как {output_file}")

if __name__ == "__main__":
    merge_translation_files()
