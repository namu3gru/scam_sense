#!/usr/bin/env python3
"""Builds ios/ScamSense/Localizable.xcstrings from the keys Xcode extracted at build time
(build/.../*.stringsdata) and the Korean table in ko_strings.py. Prints any missing translations."""
import glob, json, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from ko_strings import KO, EN_PLURAL  # noqa: E402

IOS = HERE.parent / "ios"
keys = set()
for f in glob.glob(str(IOS / "build/Build/Intermediates.noindex/ScamSense.build/*/ScamSense.build/Objects-normal/*/*.stringsdata")):
    data = json.load(open(f))
    for table, entries in data.get("tables", {}).items():
        if table == "Localizable":
            keys.update(e["key"] for e in entries)

missing = sorted(k for k in keys if k not in KO)
unused = sorted(k for k in KO if k not in keys)
strings = {}
for key in sorted(keys | set(KO)):
    loc = {}
    if key in EN_PLURAL:
        loc["en"] = {"variations": {"plural": {form: {"stringUnit": {"state": "translated", "value": v}}
                                               for form, v in EN_PLURAL[key].items()}}}
    if key in KO:
        loc["ko"] = {"stringUnit": {"state": "translated", "value": KO[key]}}
    entry = {"extractionState": "manual" if key not in keys else "extracted_with_value"}
    if loc:
        entry["localizations"] = loc
    strings[key] = entry

catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
out = IOS / "ScamSense" / "Localizable.xcstrings"
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
print(f"{len(keys)} keys, {len(missing)} missing ko, {len(unused)} unused ko entries -> {out}")
for k in missing:
    print("MISSING:", repr(k))
for k in unused:
    print("UNUSED:", repr(k))
