import json
from collections import OrderedDict

def migrate_words(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for category in data:
        new_entries = []
        for entry in category.get("entries", []):
            new_entry = OrderedDict()
            new_entry["id"] = entry["id"]
            new_entry["word"] = entry["word"]

            translation = entry.pop("translation", "")
            new_entry["translations"] = {"ru": translation}

            # Перенос остальных полей (например, examples)
            for key, value in entry.items():
                if key not in {"id", "word"}:
                    new_entry[key] = value

            new_entries.append(new_entry)

        category["entries"] = new_entries

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Использование:
migrate_words("word.json")
