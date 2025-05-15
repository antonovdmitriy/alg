import sys
import os
import requests

# 💡 Настрой свои данные
API_KEY = os.getenv("AZURE_TTS_KEY")
if not API_KEY:
    print("❌ Переменная окружения AZURE_TTS_KEY не установлена.")
    sys.exit(1)
REGION = "swedencentral"
VOICE = "sv-SE-MattiasNeural"
OUTPUT_FORMAT = "audio-48khz-192kbitrate-mono-mp3"

def synthesize_speech(text, output_path):
    url = f"https://{REGION}.tts.speech.microsoft.com/cognitiveservices/v1"

    ssml = f"""
    <speak version='1.0' xml:lang='sv-SE'>
        <voice name='{VOICE}'>{text}</voice>
    </speak>
    """

    headers = {
        "Ocp-Apim-Subscription-Key": API_KEY,
        "Content-Type": "application/ssml+xml",
        "X-Microsoft-OutputFormat": OUTPUT_FORMAT,
        "User-Agent": "SvenskaGlosorApp"
    }


    response = requests.post(url, headers=headers, data=ssml.encode("utf-8"))

    if response.status_code == 200:
        with open(output_path, "wb") as f:
            f.write(response.content)
        print(f"✅ Озвучка сохранена: {output_path}")
    else:
        print(f"❌ Ошибка {response.status_code}")
        print(response.text)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Использование: python generate_tts.py \"фраза\" path/output.mp3")
        sys.exit(1)

    phrase = sys.argv[1]
    output_file = sys.argv[2]

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    synthesize_speech(phrase, output_file)
