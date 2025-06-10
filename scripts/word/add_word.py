import json
import argparse
import uuid
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description="Add a new word to an existing category.")
parser.add_argument("--category-id", required=True, help="ID of the category to add the word to")
parser.add_argument("--word", required=True, help="Main word in Swedish")
parser.add_argument("--file", default="word.json", help="Path to the wordlist JSON file")

args = parser.parse_args()
json_path = Path(args.file)

if not json_path.exists():
    print(f"❌ File not found: {json_path}")
    sys.exit(1)

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"🔍 Searching for category ID: {args.category_id}")

category = next((cat for cat in data if cat["id"] == args.category_id), None)
if not category:
    print(f"❌ Category with ID '{args.category_id}' not found.")
    sys.exit(1)
else:
    print(f"✅ Category found: {category.get('translations', {}).get('en', '[No English title]')}")

new_word = {
    "id": str(uuid.uuid4()),
    "version": 1,
    "word": args.word,
    "forms": [],
    "translations": {},
    "examples": [],
    "voiceEntries": []
}

category["entries"].append(new_word)

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(new_word["id"])