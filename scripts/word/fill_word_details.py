import argparse
import json
import asyncio
import functools
from aiolimiter import AsyncLimiter
from openai import OpenAI

client = OpenAI()

async def generate_translation_and_details(limiter, word):
    prompt_all = (
        f"You are a helpful assistant specialized in Swedish. For the word '{word}', do the following:\n"
        f"\n"
        f"1. Translate it into English. Return it as a string in the field 'en'.\n"
        f"2. List its main inflected forms (if applicable) as a JSON array of dictionaries with key 'form'. Example:\n"
        f"   [{{\"form\": \"formen\"}}, {{\"form\": \"former\"}}]\n"
        f"3. Generate at least 10 realistic, modern Swedish example sentences using the word. Use the format:\n"
        f"   [{{\"text\": \"Första exempelmeningen.\"}}, ...]\n"
        f"\n"
        f"Reply only in the following JSON format:\n"
        f"{{\n"
        f"  \"en\": \"...\",\n"
        f"  \"forms\": [...],\n"
        f"  \"examples\": [...]\n"
        f"}}"
    )

    await limiter.acquire()
    try:
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None,
            functools.partial(
                client.chat.completions.create,
                model="gpt-4o",
                messages=[{"role": "user", "content": prompt_all}],
                temperature=0.7,
            )
        )
        raw_content = response.choices[0].message.content
        raw_content = raw_content.lstrip("\ufeff").strip()
        if raw_content.startswith("```json"):
            raw_content = raw_content[len("```json"):].strip()
        if raw_content.endswith("```"):
            raw_content = raw_content[:-3].strip()
        if not raw_content:
            print(f"❌ Empty response from OpenAI for word '{word}'")
            return None, None, None
        try:
            response_json = json.loads(raw_content)
        except json.JSONDecodeError as e:
            print(f"❌ JSON decode error for word '{word}': {e}")
            print("🔎 BEGIN RAW CONTENT (repr):\n" + repr(raw_content) + "\n🔎 END RAW CONTENT")
            return None, None, None
        en_translation = response_json.get("en")
        forms = response_json.get("forms", [])
        example_sentences = response_json.get("examples", [])
        return en_translation, forms, example_sentences
    except Exception as e:
        print(f"❌ Error generating details for word '{word}': {e}")
        print("🔎 BEGIN RAW CONTENT\n" + (raw_content if 'raw_content' in locals() else '(no content)') + "\n🔎 END RAW CONTENT")
        return None, None, None

def find_word_by_id(data, word_id):
    for category in data:
        words = category.get("entries", [])
        for word in words:
            if word.get("id") == word_id:
                return word
    return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", required=True, help="UUID of the word to fill")
    parser.add_argument("--file", default="word.json", help="Path to the word base JSON file")
    args = parser.parse_args()

    print(f"🔍 Loading word base from {args.file}")
    with open(args.file, "r", encoding="utf-8") as f:
        data = json.load(f)

    print(f"🔍 Searching for word with ID: {args.id}")
    word = find_word_by_id(data, args.id)

    if not word:
        print(f"❌ Word with ID {args.id} not found")
        exit(1)

    print(f"📝 Found word: {word.get('word')} (ID: {args.id})")
    limiter = AsyncLimiter(1, 2)

    en_translation, forms, example_sentences = asyncio.run(generate_translation_and_details(limiter, word.get("word")))

    if en_translation is None or example_sentences is None:
        print("❌ Failed to generate word details")
        exit(1)

    if forms is None:
        forms = []

    print(f"✅ Setting version to 1")
    word["version"] = 1

    print(f"✅ Setting English translation to: {en_translation}")
    translations = word.get("translations", {})
    translations["en"] = en_translation
    word["translations"] = translations

    print(f"✅ Setting inflected forms")
    word["forms"] = forms

    print(f"✅ Setting example sentences (at least 10)")
    word["examples"] = example_sentences

    print(f"💾 Saving updated word base to {args.file}")
    with open(args.file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("✅ Done")
