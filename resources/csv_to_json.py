import csv
import json
import uuid
import sys
import os

def convert(csv_path, output_path):
    excluded_categories = {
        "Рандом",
        "Рандом связки",
        "Рандом счет дата выражения"
    }

    categories = []
    if os.path.exists(output_path):
        with open(output_path, encoding="utf-8") as f:
            old_data = json.load(f)
    else:
        old_data = []

    existing_words = {entry["word"] for category in old_data for entry in category.get("entries", [])}

    current_category = None

    with open(csv_path, encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            if len(row) < 3:
                continue

            ru = row[0].strip()
            sv = row[1].strip() if row[1] else None
            example = row[2].strip() if row[2] else None

            if not sv and not example:
                if ru and ru not in excluded_categories:
                    current_category = {
                        "id": str(uuid.uuid4()),
                        "name": ru,
                        "entries": []
                    }
                    categories.append(current_category)
                else:
                    current_category = None
                continue

            if current_category and sv:
                entry = {
                    "id": str(uuid.uuid4()),
                    "word": sv,
                    "translation": ru,
                    "examples": [e.strip() for e in example.split(". ") if e.strip()] if example else []
                }
                current_category["entries"].append(entry)

    for category in categories:
        filtered_entries = []
        for entry in category["entries"]:
            if entry["word"] in existing_words:
                continue
            filtered_entries.append(entry)

        if not filtered_entries:
            continue

        for old_cat in old_data:
            if old_cat["name"] == category["name"]:
                old_cat["entries"].extend(filtered_entries)
                break
        else:
            new_cat = {
                "id": category["id"],
                "name": category["name"],
                "entries": filtered_entries
            }
            old_data.append(new_cat)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(old_data, f, ensure_ascii=False, indent=2)

    print(f"✅ JSON saved to: {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("❌ Usage: python convert_words.py <input_csv_path> <output_json_path>")
        sys.exit(1)

    csv_input = sys.argv[1]
    json_output = sys.argv[2]

    if not os.path.exists(csv_input):
        print(f"❌ File not found: {csv_input}")
        sys.exit(1)

    convert(csv_input, json_output)
