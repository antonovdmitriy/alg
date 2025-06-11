import argparse
import json
import asyncio
import functools
import os
from aiolimiter import AsyncLimiter
from openai import OpenAI
import re

client = OpenAI()
TARGET_LANGS = ["uk", "ar", "fa", "so", "es", "de", "fr", "pl", "id", "hi", "zh", "it", "tr", "sr", "fi", "et", "be", "lv", "lt", "ru"]

def extract_json(text):
    match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
    if match:
        return match.group(1)
    return text

def merge_translations(existing, new):
    for lang, translation in new.items():
        if lang not in existing:
            existing[lang] = translation
    return existing

async def translate_word_only(word, limiter):
    word_text = word.get("word", "")
    translations = word.get("translations", {})
    en_text = translations.get("en", "")
    ru_text = translations.get("ru", "")

    if not en_text:
        print(f"⚠️ Missing English translation for word '{word_text}', cannot proceed.")
        return

    messages = [
        {
            "role": "system",
            "content": (
                "You are a multilingual translator. You will be given a Swedish word with its English and optionally Russian translations. "
                "Use English as primary and Russian as optional to infer meaning and translate it into the following languages: "
                + ", ".join(TARGET_LANGS) +
                ". Reply only with a valid JSON dictionary {lang: translation}. No comments, no markdown."
            )
        },
        {
            "role": "user",
            "content": f"Swedish word: {word_text}\nEnglish: {en_text}\nRussian: {ru_text}"
        }
    ]

    await limiter.acquire()

    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None,
            functools.partial(
                client.chat.completions.create,
                model="gpt-4o",
                messages=messages,
                temperature=0
            )
        )
        content = response.choices[0].message.content
        cleaned = extract_json(content)
        parsed = json.loads(cleaned)
        print(f"🌍 New translations: {parsed}")
        word["translations"] = merge_translations(translations, parsed)
    except Exception as e:
        print(f"❌ Error during translation: {e}")

async def main():
    parser = argparse.ArgumentParser(description="Translate a single word to multiple languages.")
    parser.add_argument("--id", required=True, help="UUID of the word")
    parser.add_argument("--file", default="resources/word.json", help="Path to the word base JSON file")
    args = parser.parse_args()

    file_path = args.file
    word_id = args.id

    if not os.path.isfile(file_path):
        print(f"❌ File not found: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    found_word = None
    for category in data:
        for word in category.get("entries", []):
            if word.get("id") == word_id:
                found_word = word
                break
        if found_word:
            break

    if not found_word:
        print(f"❌ Word with ID '{word_id}' not found.")
        return

    limiter = AsyncLimiter(1, 2)
    await translate_word_only(found_word, limiter)

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("✅ Word translations updated.")

if __name__ == "__main__":
    asyncio.run(main())
