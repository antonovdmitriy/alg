import json
from pathlib import Path

INPUT_PATH = "./word.json"
OUTPUT_PATH = "./word_migrated.json"

def migrate_examples_to_objects():
    with open(INPUT_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    changed = False
    for category in data:
        for entry in category.get("entries", []):
            examples = entry.get("examples")
            if examples and isinstance(examples, list) and all(isinstance(e, str) for e in examples):
                entry["examples"] = [{"text": e} for e in examples]
                changed = True

    if changed:
        with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ Migration complete. Output saved to {OUTPUT_PATH}")
    else:
        print("ℹ️ No changes needed. Already in new format.")

if __name__ == "__main__":
    migrate_examples_to_objects()
