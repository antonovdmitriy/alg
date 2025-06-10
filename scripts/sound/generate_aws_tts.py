import sys
import os
import boto3

VOICE = "Elin"  # Шведский голос
OUTPUT_FORMAT = "mp3"
REGION = "us-east-1"

# Проверка переменных окружения
if not os.getenv("AWS_ACCESS_KEY_ID") or not os.getenv("AWS_SECRET_ACCESS_KEY"):
    print("❌ AWS credentials are not set (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY).")
    sys.exit(1)

polly = boto3.client("polly", region_name=REGION)


def synthesize_speech(text, output_path, phoneme=None):
    if phoneme:
        text_part = f"<phoneme alphabet='ipa' ph='{phoneme}'>{text}</phoneme>"
    else:
        text_part = text

    ssml = f"""<speak xmlns="http://www.w3.org/2001/10/synthesis" version="1.0" xml:lang="sv-SE">
    {text_part}
</speak>"""

    print("🧪 SSML:")
    print(ssml)

    try:
        response = polly.synthesize_speech(
            Text=ssml,
            VoiceId=VOICE,
            OutputFormat=OUTPUT_FORMAT,
            TextType="ssml",
            Engine="neural"
        )
    except Exception as e:
        print(f"❌ Polly error: {e}")
        return

    if "AudioStream" in response:
        with open(output_path, "wb") as f:
            f.write(response["AudioStream"].read())
        print(f"✅ Audio saved: {output_path}")
    else:
        print("❌ No audio stream returned.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python generate_aws_tts.py \"text\" path/output.mp3 [--phoneme \"transcription\"]")
        sys.exit(1)

    phrase = sys.argv[1]
    output_file = sys.argv[2]

    phoneme = None
    if len(sys.argv) > 3 and sys.argv[3] == "--phoneme" and len(sys.argv) > 4:
        phoneme = sys.argv[4]

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    synthesize_speech(phrase, output_file, phoneme)
