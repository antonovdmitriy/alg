import json

with open("word.json", encoding="utf-8") as f:
    data = json.load(f)

bad_ids = []

for category in data:
    for entry in category.get("entries", []):
        for example in entry.get("examples", []):
            text = example.get("text", "")
            if "?" in text[:-1] or "!" in text[:-1]:
                bad_ids.append((entry["id"], text))
                break  # Только один пример на слово достаточно

print("Word IDs with misplaced punctuation:")
for wid, example_text in bad_ids:
    print(f"{wid}: {example_text}")
