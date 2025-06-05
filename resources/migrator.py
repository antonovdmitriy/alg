import json
import re

# Путь к файлу со словами
INPUT_JSON = "word.json"
OUTPUT_JSON = "word_migrated.json"


def load_bad_ids(path):
    """
    Returns: dict mapping word id (str) -> set of example indexes (int) to split
    examples_to_fix file format:
        word_id [example i]: text
    """
    id_map = {}
    pattern = re.compile(r"^(?P<word_id>\S+)\s+\[example\s+(?P<index>\d+)\]:")
    with open(path, encoding="utf-8") as f:
        next(f)  # Пропускаем заголовок
        for line in f:
            line = line.strip()
            match = pattern.match(line)
            if match:
                word_id = match.group("word_id")
                index = int(match.group("index"))
                if word_id not in id_map:
                    id_map[word_id] = set()
                id_map[word_id].add(index)
    return id_map

# Загрузка словаря id -> set(индексы примеров) из файла
BAD_IDS_BY_EXAMPLE_INDEX = load_bad_ids("examples_to_fix")

# Регулярка для разбиения текста на предложения
SENTENCE_REGEX = re.compile(r'(?<=[.?!])\s+(?=\S)')

with open(INPUT_JSON, encoding="utf-8") as f:
    data = json.load(f)

changed_count = 0

for category in data:
    for entry in category.get("entries", []):
        if entry["id"] not in BAD_IDS_BY_EXAMPLE_INDEX:
            continue

        bad_indexes = BAD_IDS_BY_EXAMPLE_INDEX[entry["id"]]
        orig_examples = entry.get("examples", [])
        new_examples = []
        changed = False
        for i, example in enumerate(orig_examples):
            if i in bad_indexes:
                parts = SENTENCE_REGEX.split(example["text"].strip())
                parts_clean = [part.strip(" \t\n\r") for part in parts if part.strip(" \t\n\r")]
                for part in parts_clean:
                    new_examples.append({"text": part})
                if len(parts_clean) != 1 or parts_clean[0] != example["text"].strip():
                    changed = True
            else:
                new_examples.append(example)

        if changed and new_examples != orig_examples:
            entry["examples"] = new_examples
            entry["version"] += 1
            changed_count += 1
            print(f'"{entry["id"]}",')

# Сохраняем результат
with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n🔁 Migration complete. Entries changed: {changed_count}")
