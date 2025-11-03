#!/usr/bin/env python3
"""
translate_missing.py

This script translates missing or empty keys from the English i18n YAML
file (hyrax.en.yml) into one or more target languages using a local
LibreTranslate endpoint.

Why Python?
- Preserves YAML formatting, comments, and inline/block style using ruamel.yaml
- Ruby's built-in YAML tools rewrite formatting, causing unnecessary diffs
  in Git when only translation values change.
- This script is run occasionally, so introducing a small Python helper
  is practical for keeping translation diffs clean.

Usage:

Set Up:
    1. Make sure LibreTranslate is running locally in a separate shell:
       $ pip install libretranslate
       $ libretranslate

Run the script:

    All at once (multiple languages):
        $ python translate_missing.py es zh it fr pt-BR

    One at a time (single language):
        $ python translate_missing.py es
"""
import json
import sys
import time
import requests
from ruamel.yaml import YAML
from pathlib import Path

# ----------------------
# Configuration
# ----------------------
SOURCE_LANG = "en"
INPUT_FILE = Path("config/locales/hyrax.en.yml")
LIBRETRANSLATE_URL = "http://127.0.0.1:5000/translate"

yaml = YAML()
yaml.explicit_start = True       # Add '---' at the top
yaml.preserve_quotes = True
yaml.width = 4096  # avoid folding long lines

# ----------------------
# Load source YAML once
# ----------------------
source_data = yaml.load(INPUT_FILE.read_text())
source = source_data[SOURCE_LANG]

# ----------------------
# Translation helper
# ----------------------
def translate_text(text, source_lang=SOURCE_LANG, target_lang="es"):
    if text is None or str(text).strip() == "":
        return text
    try:
        resp = requests.post(
            LIBRETRANSLATE_URL,
            data={"q": text, "source": source_lang, "target": target_lang},
        )
        resp.raise_for_status()
        translated = json.loads(resp.text)["translatedText"]
        print(f"Translated ({target_lang}): {text} → {translated}")
        return translated
    except Exception as e:
        print(f"⚠️ Translation error for '{text}': {e}")
        return text

# ----------------------
# Recursive merge & translate
# ----------------------
def deep_merge_translate(source_dict, target_dict, target_lang):
    result = target_dict.copy()
    for key, value in source_dict.items():
        if isinstance(value, dict):
            result[key] = deep_merge_translate(value, result.get(key, {}), target_lang)
        else:
            if key not in result or str(result[key]).strip() == "":
                result[key] = translate_text(value, target_lang=target_lang)
    return result

# ----------------------
# Main loop over target languages
# ----------------------
if len(sys.argv) < 2:
    print("Usage: python translate_locales.py <lang1> [<lang2> ...]")
    sys.exit(1)

for target_lang in sys.argv[1:]:
    print(f"\n=== Translating into {target_lang} ===")
    output_file = Path(f"config/locales/hyrax.{target_lang}.yml")

    # Load existing target YAML if present
    if output_file.exists():
        target_data = yaml.load(output_file.read_text())
        target = target_data.get(target_lang, {})
    else:
        target = {}

    # Merge and translate
    merged = deep_merge_translate(source, target, target_lang)

    # Write back preserving formatting
    output_data = {target_lang: merged}
    with output_file.open("w") as f:
        yaml.dump(output_data, f)

    print(f"✅ Updated {output_file} — existing translations preserved.")