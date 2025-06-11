import json
import argparse
import uuid
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description="Add a new category.")
parser.add_argument("--title", required=True, help="Category title in English (default)")
parser.add_argument("--file", default="word.json", help="Path to the wordlist JSON file")

args = parser.parse_args()
json_path = Path(args.file)

if not json_path.exists():
    print(f"❌ File not found: {json_path}")
    sys.exit(1)

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Check for duplicate title in any translation
for category in data:
    translations = category.get("translations", {})
    if args.title in translations.values():
        print(f"⚠️ Category with title '{args.title}' already exists.")
        sys.exit(1)

new_id = str(uuid.uuid4())

new_category = {
    "id": new_id,
    "translations": {
        "en": args.title
    },
    "entries": []
}

data.append(new_category)

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(new_category["id"])