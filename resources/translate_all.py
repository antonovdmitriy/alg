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

def find_entry_by_id(data, entry_id):
    for category in data:
        for entry in category.get("entries", []):
            if entry.get("id") == entry_id:
                return entry
    return None

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

async def process_entry(limiter, entry):
    ru_word = entry.get("translations", {}).get("ru")
    en_word = entry.get("translations", {}).get("en", "")
    print(f"🔍 Слово: '{entry.get('word')}', ru: '{ru_word}', en: '{en_word}'")
    if ru_word:
        translated = await translate_from_ru_and_en_async(limiter, ru_word, en_word)
        print(f"➡️ Добавленные переводы: {translated}")
        entry["translations"] = merge_translations(entry.get("translations", {}), translated)

async def process_category(limiter, category):
    ru_cat = category.get("translations", {}).get("ru", "")
    en_cat = category.get("translations", {}).get("en", "")
    if ru_cat:
        translated_cat = await translate_from_ru_and_en_async(limiter, ru_cat, en_cat)
        category["translations"] = merge_translations(category.get("translations", {}), translated_cat)

    tasks = []
    for entry in category.get("entries", []):
        tasks.append(process_entry(limiter, entry))
    await asyncio.gather(*tasks)

async def translate_all_async(input_path, args):
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    limiter = AsyncLimiter(1, 2)  # 1 request every 2 seconds
    for category in data:
        await process_category(limiter, category)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    return data

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="UUID of specific word entry to translate")
    parser.add_argument("--category", help="ID категории для перевода")
    parser.add_argument("--categories", help="IDs категорий, разделённые запятой")
    parser.add_argument("--input", default="word.json", help="Path to input JSON")
    parser.add_argument("--output", default="translated_words.json", help="Path to output JSON")
    args = parser.parse_args()

    if args.id:
        with open(args.input, "r", encoding="utf-8") as f:
            data = json.load(f)
        print(f"🎯 Переводим только слово с ID: {args.id}")
        entry = find_entry_by_id(data, args.id)
        if entry:
            ru_text = entry.get("translations", {}).get("ru")
            en_text = entry.get("translations", {}).get("en", "")
            if ru_text:
                translated = asyncio.run(translate_from_ru_and_en_async(AsyncLimiter(1,2), ru_text, en_text))
                entry["translations"] = merge_translations(entry.get("translations", {}), translated)
            else:
                print("⚠️ Нет русского перевода у записи")
        else:
            print("❌ Запись с таким ID не найдена")
    elif args.category:
        with open(args.input, "r", encoding="utf-8") as f:
            data = json.load(f)

        selected_category = next((cat for cat in data if cat.get("id") == args.category), None)
        if selected_category:
            print(f"🎯 Переводим только категорию с ID: {args.category}")
            asyncio.run(process_category(AsyncLimiter(1,2), selected_category))
            with open(f"translated_{args.category}.json", "w", encoding="utf-8") as f:
                json.dump(selected_category, f, ensure_ascii=False, indent=2)
        else:
            print("❌ Категория с таким ID не найдена")
    elif args.categories:
        with open(args.input, "r", encoding="utf-8") as f:
            data = json.load(f)

        category_ids = [c.strip() for c in args.categories.split(",")]
        for cid in category_ids:
            selected_category = next((cat for cat in data if cat.get("id") == cid), None)
            if selected_category:
                print(f"🎯 Переводим категорию с ID: {cid}")
                asyncio.run(process_category(AsyncLimiter(1, 2), selected_category))
                with open(f"translated_{cid}.json", "w", encoding="utf-8") as f:
                    json.dump(selected_category, f, ensure_ascii=False, indent=2)
            else:
                print(f"❌ Категория с ID {cid} не найдена")
    else:
        data = asyncio.run(translate_all_async(args.input, args))
        print(f"✅ Сохранено в {args.output}")
