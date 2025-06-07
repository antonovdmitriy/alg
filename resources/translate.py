import os
import openai
import json

client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

def translate_word(word, ru_translation):
    if not client.api_key:
        raise RuntimeError("OPENAI_API_KEY is not set.")

    messages = [
        {"role": "system", "content": (
            "You are a translator. You will be given a Swedish word and its meaning in Russian. "
            "Your task is to translate that meaning into the following 15 languages: "
            "en, uk, ar, fa, so, es, de, fr, pl, id, hi, zh, it, tr, sr. "
            "Respond only with a valid JSON object with language codes as keys and translated words as values. "
            "Do not explain anything."
        )},
        {"role": "user", "content": f"Swedish word: '{word}'\nRussian meaning: '{ru_translation}'"}
    ]

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            temperature=0
        )
        content = response.choices[0].message.content
        print("✅ Ответ от GPT:")
        print(content)

        # Удалим markdown-обертку ```json
        import re
        def extract_json(text):
            match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
            if match:
                return match.group(1)
            return text

        cleaned = extract_json(content)
        parsed = json.loads(cleaned)
        print("✅ Успешно разобрано как JSON:")
        print(json.dumps(parsed, indent=2, ensure_ascii=False))

    except Exception as e:
        print("❌ Ошибка:")
        print(e)

if __name__ == "__main__":
    translate_word("betyg", "оценка (в школе)")
