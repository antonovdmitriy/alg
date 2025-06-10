import argparse
import json
import re
import asyncio
import functools
from aiolimiter import AsyncLimiter

from openai import OpenAI

client = OpenAI()

TARGET_LANGS = ["uk", "ar", "fa", "so", "es", "de", "fr", "pl", "id", "hi", "zh", "it", "tr", "sr", "fi", "et", "be", "lv", "lt"]

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

async def translate_from_ru_and_en_async(limiter, ru_text, en_text=""):
    messages = [
        {
            "role": "system",
            "content": (
                "You are a multilingual translator. You will be given a phrase with its Russian and English translations. "
                "Use both to infer meaning and translate it into the following languages: "
                + ", ".join(TARGET_LANGS) +
                ". Reply only with a valid JSON dictionary {lang: translation}. No comments, no markdown."
            )
        },
        {
            "role": "user",
            "content": f"Russian: {ru_text}\nEnglish: {en_text}"
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
        return parsed
    except Exception as e:
        print(f"❌ Ошибка при переводе '{ru_text}': {e}")
        return {}

async def translate_category_only(category, limiter):
    print(f"🛠️ Translating category only: {category.get('id')}")
    translations = category.get("translations", {})
    en_cat = translations.get("en", "")
    ru_cat = translations.get("ru")

    if not en_cat:
        print("❌ Нет английского перевода, перевод невозможен")
        return

    print(f"🔤 Source: en='{en_cat}' | ru='{ru_cat}'")

    translated_cat = await translate_from_ru_and_en_async(limiter, ru_cat or "", en_cat)
    print(f"➡️ Translations: {translated_cat}")
    category["translations"] = merge_translations(category.get("translations", {}), translated_cat)
    print(f"📝 After merge: {category['translations']}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="ID категории для перевода")
    parser.add_argument("--file", default="resources/word.json", help="Path to the JSON file")
    args = parser.parse_args()
    print(f"🧩 Аргументы командной строки: {args}")

    if args.id:
        input_path = args.file
        with open(input_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        selected_category = next((cat for cat in data if cat.get("id") == args.id), None)
        print(f"🔍 Ищем категорию с ID: {args.id}")
        if selected_category:
            print(f"🎯 Translating category '{args.id}' only")
            limiter = AsyncLimiter(1, 2)
            asyncio.run(translate_category_only(selected_category, limiter))
            with open(input_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"✅ Сохранено в {input_path}")
        else:
            print("❌ Категория с таким ID не найдена")
            exit(1)
    else:
        print("❌ Не указан ID категории для перевода")
        exit(1)
