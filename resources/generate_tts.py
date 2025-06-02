import sys
import os
import requests

# 💡 Configure your credentials
API_KEY = os.getenv("AZURE_TTS_KEY")
if not API_KEY:
    print("❌ Environment variable AZURE_TTS_KEY is not set.")
    sys.exit(1)
REGION = "swedencentral"
VOICE = "sv-SE-MattiasNeural"
OUTPUT_FORMAT = "audio-48khz-192kbitrate-mono-mp3"

def synthesize_speech(text, output_path, phoneme=None):
    if phoneme:
        text_part = f"<phoneme alphabet='ipa' ph='{phoneme}'>{text}</phoneme>"
    else:
        text_part = text

    ssml = f"""
    <speak version='1.0' xml:lang='sv-SE'>
        <voice name='{VOICE}'>{text_part}</voice>
    </speak>
    """

    print("🧪 SSML:")
    print(ssml)

    url = f"https://{REGION}.tts.speech.microsoft.com/cognitiveservices/v1"

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
        print(f"✅ Audio saved: {output_path}")
    else:
        print(f"❌ Error {response.status_code}")
        print(response.text)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python generate_tts.py \"text\" path/output.mp3 [--phoneme \"transcription\"]")
        sys.exit(1)

    phrase = sys.argv[1]
    output_file = sys.argv[2]

    phoneme = None
    if len(sys.argv) > 3 and sys.argv[3] == "--phoneme" and len(sys.argv) > 4:
        phoneme = sys.argv[4]

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    synthesize_speech(phrase, output_file, phoneme)
