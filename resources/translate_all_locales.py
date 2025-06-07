import argparse
import json
import re
import asyncio
import functools
import os
from aiolimiter import AsyncLimiter
import requests

TARGET_LANGS = ["uk", "ar", "es", "de", "fr", "pl", "id", "hi", "zh", "it", "tr", "fi"]

async def translate_phrase(limiter, en_text, ru_text=""):
    prompt = (
        "Translate the following English phrase into the following languages, using the Russian variant as an additional reference when needed: "
        + ", ".join(TARGET_LANGS) +
        "\nEnglish: " + en_text +
        "\nRussian: " + ru_text +
        "\nReturn a valid JSON object in the format { \"uk\": \"...\", \"pl\": \"...\", ... }"
    )

    messages = [
        {
            "role": "system",
            "content": "You are a multilingual translator. Provide only a valid JSON dictionary with translations."
        },
        {
            "role": "user",
            "content": prompt
        }
    ]

    await limiter.acquire()

    try:
        loop = asyncio.get_running_loop()
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {os.getenv('OPENAI_API_KEY')}"
        }

        data = {
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0
        }

        response = await loop.run_in_executor(
            None,
            functools.partial(requests.post,
                "https://api.openai.com/v1/chat/completions",
                headers=headers,
                json=data
            )
        )

        print("📡 Raw OpenAI response:", response.text)

        content = response.json()["choices"][0]["message"]["content"]

        # Вырезаем JSON из блока ```json ... ```
        match = re.search(r"```json\s*(\{.*?\})\s*```", content, re.DOTALL)
        if not match:
            raise ValueError("Ответ не содержит JSON-блока")
        parsed = json.loads(match.group(1))
        return parsed
    except Exception as e:
        print(f"❌ Ошибка при обработке ответа OpenAI для '{en_text}': {e}")
        return {}

async def main(input_path, output_path):
    # 1. Загрузить входной файл
    with open(input_path, "r", encoding="utf-8") as f:
        input_data = json.load(f)

    limiter = AsyncLimiter(1, 2)  # 1 запрос каждые 2 секунды

    en_items = {}
    ru_items = {}
    sv_items = {}

    strings = input_data.get("strings", {})
    if not strings:
        raise ValueError("Не найдена секция 'strings' в .xcstrings файле")

    for key, data in strings.items():
        en_val = data.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value")
        if en_val:
            en_items[key] = en_val
        ru_val = data.get("localizations", {}).get("ru", {}).get("stringUnit", {}).get("value")
        if ru_val:
            ru_items[key] = ru_val
        sv_val = data.get("localizations", {}).get("sv", {}).get("stringUnit", {}).get("value")
        if sv_val:
            sv_items[key] = sv_val

    result = {}

    for key, en_text in en_items.items():
        ru_text = ru_items.get(key, "")
        sv_text = sv_items.get(key, "")
        print(f"🔍 Переводим ключ: '{key}', en: '{en_text}', ru: '{ru_text}'")
        translations = await translate_phrase(limiter, en_text, ru_text)
        
        entry = {
            "extractionState": "manual",
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": en_text
                    }
                }
            }
        }

        if ru_text:
            entry["localizations"]["ru"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": ru_text
                }
            }
        if sv_text:
            entry["localizations"]["sv"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": sv_text
                }
            }

        for lang in TARGET_LANGS:
            val = translations.get(lang)
            if val:
                entry["localizations"][lang] = {
                    "stringUnit": {
                        "state": "translated",
                        "value": val
                    }
                }

        result[key] = entry
        print(f"➡️ Добавлены переводы для ключа '{key}': {translations}")

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"sourceLanguage": "en", "strings": result}, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="Localizable.xcstrings", help="Path to input JSON")
    parser.add_argument("--output", default="Localizable_translated.xcstrings", help="Path to output JSON")
    args = parser.parse_args()

    asyncio.run(main(args.input, args.output))
    print(f"✅ Сохранено в {args.output}")
