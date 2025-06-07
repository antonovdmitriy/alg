import argparse
import json
import os
import time
import re
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


TARGET_LANGS = ["en", "uk", "ar", "fa", "so", "es", "de", "fr", "pl", "id", "hi", "zh", "it", "tr", "sr"]

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

def translate_from_ru_and_en(ru_text, en_text=""):
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

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            temperature=0
        )
        content = response.choices[0].message.content
        cleaned = extract_json(content)
        parsed = json.loads(cleaned)
        return parsed
    except Exception as e:
        print(f"❌ Ошибка при переводе '{ru_text}': {e}")
        return {}

def translate_all(input_path):
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    for category in data:
        ru_cat = category.get("translations", {}).get("ru", "")
        en_cat = category.get("translations", {}).get("en", "")
        if ru_cat:
            translated_cat = translate_from_ru_and_en(ru_cat, en_cat)
            category["translations"] = merge_translations(category.get("translations", {}), translated_cat)

        for entry in category.get("entries", []):
            ru_word = entry.get("translations", {}).get("ru")
            en_word = entry.get("translations", {}).get("en", "")
            print(f"🔍 Слово: '{entry.get('word')}', ru: '{ru_word}', en: '{en_word}'")
            if ru_word:
                translated = translate_from_ru_and_en(ru_word, en_word)
                print(f"➡️ Добавленные переводы: {translated}")
                entry["translations"] = merge_translations(entry.get("translations", {}), translated)

    return data

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="UUID of specific word entry to translate")
    parser.add_argument("--input", default="word_test.json", help="Path to input JSON")
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
                translated = translate_from_ru_and_en(ru_text, en_text)
                entry["translations"] = merge_translations(entry.get("translations", {}), translated)
            else:
                print("⚠️ Нет русского перевода у записи")
        else:
            print("❌ Запись с таким ID не найдена")
    else:
        data = translate_all(args.input)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"✅ Сохранено в {args.output}")
