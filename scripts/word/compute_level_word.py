import argparse
import json
import asyncio
import functools
import os
from aiolimiter import AsyncLimiter
from openai import OpenAI
import re

client = OpenAI()

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


async def determine_word_level(word, limiter, fallback_to_word_only=False):
    word_text = word.get("word", "")
    translations = word.get("translations", {})
    ru_text = translations.get("ru", "")

    if not ru_text and not fallback_to_word_only:
        print(f"⚠️ Missing Russian translation for word '{word_text}', cannot determine level.")
        return

    if ru_text:
        # Use system prompt for Swedish + Russian translation
        system_prompt = (
            "You are a language proficiency assessor. Given a Swedish word and its Russian translation, determine the CEFR language level of the word (one of A1, A2, B1, B2, C1, C2). "
            "Reply only with a JSON object like {\"level\": \"a1\"} in lowercase, without any markdown or additional text."
        )
        user_content = f"Swedish word: {word_text}\nRussian translation: {ru_text}"
    else:
        # Use system prompt for Swedish word only
        system_prompt = (
            "You are a language proficiency assessor. Given only a Swedish word, determine the CEFR language level of the word (one of A1, A2, B1, B2, C1, C2). "
            "Reply only with a JSON object like {\"level\": \"a1\"} in lowercase, without any markdown or additional text."
        )
        user_content = f"Swedish word: {word_text}"

    messages = [
        {
            "role": "system",
            "content": system_prompt
        },
        {
            "role": "user",
            "content": user_content
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
        level = parsed.get("level")
        if level:
            word["level"] = level
            print(f"🔤 Determined level for '{word_text}': {level}")
        else:
            print(f"❌ Could not determine level for word '{word_text}'.")
    except Exception as e:
        print(f"❌ Error during level determination: {e}")

async def main():
    parser = argparse.ArgumentParser(description="Translate a single word to multiple languages or determine word levels.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--id", help="UUID of the word")
    group.add_argument("--all", action="store_true", help="Process all words")
    parser.add_argument("--file", default="resources/word.json", help="Path to the word base JSON file")
    parser.add_argument("--overwrite", action="store_true", default=False, help="Overwrite existing level values")
    parser.add_argument("--fallback-to-word-only", action="store_true", default=False, help="Fallback to using only the word if Russian translation is missing")
    args = parser.parse_args()

    file_path = args.file

    if not os.path.isfile(file_path):
        print(f"❌ File not found: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    limiter = AsyncLimiter(1, 2)

    if args.id:
        word_id = args.id
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

        # Check for existing level unless overwrite is specified
        if not args.overwrite and "level" in found_word:
            print(f"⏭️ Skipping '{found_word.get('word', '')}', already has level: {found_word['level']}")
        else:
            await determine_word_level(found_word, limiter, fallback_to_word_only=args.fallback_to_word_only)

    elif args.all:
        for category in data:
            for word in category.get("entries", []):
                if not args.overwrite and "level" in word:
                    print(f"⏭️ Skipping '{word.get('word', '')}', already has level: {word['level']}")
                    continue
                await determine_word_level(word, limiter, fallback_to_word_only=args.fallback_to_word_only)

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("✅ Word levels updated.")

if __name__ == "__main__":
    asyncio.run(main())
