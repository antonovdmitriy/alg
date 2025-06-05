import json
import re

with open("word.json", encoding="utf-8") as f:
    data = json.load(f)

bad_ids = []

for category in data:
    for entry in category.get("entries", []):
        word_forms = [entry["word"]] + [f["form"] for f in entry.get("forms", [])]
        for example in entry.get("examples", []):
            text = example.get("text", "")
            sentences = re.split(r'(?<=[.?!])\s+(?=\S)', text)
            for i in range(len(sentences) - 1):
                s1 = sentences[i].lower()
                s2 = sentences[i+1].lower()
                if any(wf.lower() in s1 for wf in word_forms) and any(wf.lower() in s2 for wf in word_forms):
                    bad_ids.append((entry["id"], entry["examples"].index(example), text))
                    break

print("Word IDs with misplaced punctuation:")
for wid, index, example_text in bad_ids:
    print(f"{wid} [example {index}]: {example_text}")
