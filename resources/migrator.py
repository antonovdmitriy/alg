


INPUT_JSON = "word.json"
OUTPUT_JSON = "word_migrated.json"


def migrate_voice_entries_to_uuid_list(data):
    for category in data:
        for entry in category.get("entries", []):
            voice_entries = entry.get("voiceEntries")
            if voice_entries and isinstance(voice_entries, list) and isinstance(voice_entries[0], dict):
                entry["voiceEntries"] = [ve["id"] for ve in voice_entries if "id" in ve]
    return data


import json

if __name__ == "__main__":
    with open(INPUT_JSON, encoding="utf-8") as f:
        data = json.load(f)

    migrated_data = migrate_voice_entries_to_uuid_list(data)

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(migrated_data, f, ensure_ascii=False, indent=2)

    print(f"Migrated data written to {OUTPUT_JSON}")
