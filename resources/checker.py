import json
from collections import defaultdict

# Путь к файлу
file_path = "word.json"

# Словари для проверки дубликатов
id_counts = defaultdict(int)

try:
    with open(file_path, "r", encoding="utf-8") as f:
        categories = json.load(f)

    total_words = 0
    duplicate_ids = []

    for category in categories:
        for entry in category.get("entries", []):
            entry_id = entry.get("id")
            if entry_id:
                id_counts[entry_id] += 1
                if id_counts[entry_id] == 2:
                    duplicate_ids.append(entry_id)
                total_words += 1

    print(f"🔍 Всего слов: {total_words}")
    if duplicate_ids:
        print(f"⚠️ Найдены дубликаты ID ({len(duplicate_ids)}):")
        for dup_id in duplicate_ids:
            print(f"  - {dup_id}")
    else:
        print("✅ Дубликатов ID не найдено.")

except Exception as e:
    print(f"Ошибка при обработке файла: {e}")
