
import json

INPUT_PATH = "./word_migrated.json"

def check_versions_and_voice_entries():
    with open(INPUT_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    all_ok = True
    for category in data:
        for entry in category.get("entries", []):
            wid = entry.get("id", "<no id>")
            version = entry.get("version")
            voice_entries = entry.get("voiceEntries")

            if version != 0:
                print(f"❌ Word {wid} has invalid or missing version: {version}")
                all_ok = False

            if not isinstance(voice_entries, list) or not voice_entries or "id" not in voice_entries[0]:
                print(f"❌ Word {wid} has missing or invalid voiceEntries: {voice_entries}")
                all_ok = False

    if all_ok:
        print("✅ All entries have version = 0 and valid voiceEntries.")

if __name__ == "__main__":
    check_versions_and_voice_entries()
