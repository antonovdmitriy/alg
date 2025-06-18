import json
import argparse
import uuid
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description="Add a new word to an existing category.")
parser.add_argument("--category-id", required=True, help="ID of the category to add the word to")
parser.add_argument("--word", required=True, help="Main word in Swedish")
parser.add_argument("--file", default="word.json", help="Path to the wordlist JSON file")
parser.add_argument("--json", action="store_true", help="Output result in JSON format")
parser.add_argument("--quiet", action="store_true", help="Suppress all logs and output only the ID")

args = parser.parse_args()
json_path = Path(args.file)

if not json_path.exists():
    print(f"❌ File not found: {json_path}", file=sys.stderr)
    sys.exit(1)

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

if not args.quiet:
    print(f"🔍 Searching for category ID: {args.category_id}", file=sys.stderr)

category = next((cat for cat in data if cat["id"] == args.category_id), None)
if not category:
    print(f"❌ Category with ID '{args.category_id}' not found.", file=sys.stderr)
    sys.exit(1)
else:
    if not args.quiet:
        print(f"✅ Category found: {category.get('translations', {}).get('en', '[No English title]')}", file=sys.stderr)

new_word = {
    "id": str(uuid.uuid4()),
    "version": 1,
    "word": args.word,
    "forms": [],
    "translations": {},
    "examples": [],
    "voiceEntries": [],
    "level": ""
}

category["entries"].append(new_word)

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

if args.json:
    print(json.dumps({"id": new_word["id"]}))
elif args.quiet:
    print(new_word["id"])
else:
    print(new_word["id"])