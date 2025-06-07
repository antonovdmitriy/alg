

import json
import os

def validate_and_count(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Ошибка в JSON файле {filepath}: {e}")
        return None
    except Exception as e:
        print(f"⚠️ Не удалось открыть {filepath}: {e}")
        return None

    if not isinstance(data, list):
        print(f"❌ {filepath} должен содержать список категорий")
        return None

    total_categories = len(data)
    total_words = 0
    total_examples = 0

    for category in data:
        if not isinstance(category, dict) or "entries" not in category:
            print(f"❌ Категория некорректна: {category}")
            return None
        total_words += len(category["entries"])
        for entry in category["entries"]:
            if not isinstance(entry, dict) or "examples" not in entry:
                print(f"❌ Слово некорректно: {entry}")
                return None
            total_examples += len(entry["examples"])

    print("✅ JSON файл корректен.")
    print(f"📚 Категорий: {total_categories}")
    print(f"🗂️ Слов: {total_words}")
    print(f"💬 Примеров: {total_examples}")

if __name__ == "__main__":
    filepath = "word_translated.json"  # замените на путь к своему файлу
    validate_and_count(filepath)
