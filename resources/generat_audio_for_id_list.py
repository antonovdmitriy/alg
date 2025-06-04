import subprocess

# List of word IDs for which audio should be generated
word_ids = [
    ""
    # add more UUIDs here
]

for wid in word_ids:
    print(f"▶️ Generating audio for word {wid}")
    subprocess.run(["python3", "generate_audio_for_words.py", "--id", wid, "--override"], check=True)
