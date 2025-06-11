import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--file', required=True, help='Input file with first line as category_id, followed by words')
args = parser.parse_args()

with open(args.file, encoding="utf-8") as f:
    lines = [line.strip() for line in f if line.strip()]
    category_id = lines[0]
    for word in lines[1:]:
        print(f"\n📘 Adding word: {word}")
        result = subprocess.run(
            ["task", "add-word-full", f"CATEGORY_ID={category_id}", f"WORD={word}"],
            capture_output=False,
        )