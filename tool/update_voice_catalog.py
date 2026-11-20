"""Refresh the public mainland realtime voice snapshot; no API key is used."""

import argparse
import hashlib
import json
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urlparse

SOURCE = "https://platform.vidu.cn/vidu-stream/doc/voice-list"
ROOT = Path(__file__).resolve().parent.parent


class Scripts(HTMLParser):
    def __init__(self):
        super().__init__()
        self.inside = False
        self.values = []

    def handle_starttag(self, tag, attrs):
        if tag == "script":
            self.inside = True

    def handle_endtag(self, tag):
        if tag == "script":
            self.inside = False

    def handle_data(self, data):
        if self.inside:
            self.values.append(data)


class AliAudioTable(HTMLParser):
    """Join each row's code with its audio, including lazy/source markup."""

    def __init__(self):
        super().__init__()
        self.rows = []
        self.codes = []
        self.audio = set()
        self.in_code = False

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self.codes, self.audio = [], set()
        elif tag == "code":
            self.in_code = True
            self.codes.append("")
        elif tag in ("audio", "source"):
            attrs = dict(attrs)
            url = attrs.get("src") or attrs.get("data-src")
            if url:
                self.audio.add(url)

    def handle_data(self, data):
        if self.in_code:
            self.codes[-1] += data

    def handle_endtag(self, tag):
        if tag == "code":
            self.in_code = False
        elif tag == "tr" and self.codes:
            self.rows.append((self.codes, self.audio))


def ali_media_from_html(html, voices):
    table = AliAudioTable()
    table.feed(html)
    known = {v["voiceType"] for v in voices if v["provider"] == "qwen_omni"}
    media = {}
    for codes, urls in table.rows:
        if len(codes) != 1 or codes[0].strip() not in known:
            continue
        code = codes[0].strip()
        if len(urls) != 1:
            raise ValueError(f"Missing or ambiguous audio for {code}")
        url = next(iter(urls))
        if urlparse(url).scheme != "https" or not urlparse(url).netloc:
            raise ValueError(f"Invalid public audio URL for {code}")
        if code in media and media[code]["TrialURL"] != url:
            raise ValueError(f"Conflicting audio rows for {code}")
        media[code] = {"TrialURL": url}
    if not media:
        raise ValueError("No matching Ali audio rows; snapshot unchanged")
    return media


def catalog_from_html(html):
    parser = Scripts()
    parser.feed(html)
    for script in parser.values:
        prefix = "self.__next_f.push("
        if not script.startswith(prefix):
            continue
        row = json.loads(script[len(prefix):-1])
        if len(row) < 2 or not isinstance(row[1], str):
            continue
        marker = '"voiceCatalog":{"voices":'
        offset = row[1].find(marker)
        if offset < 0:
            continue
        value, _ = json.JSONDecoder().raw_decode(
            row[1][offset + len('"voiceCatalog":'):]
        )
        # The official site maps ali to qwen_omni, doubao3 to mainland doubao,
        # doubao2 to overseas doubao, and async to the non-realtime product.
        providers = {"ali": "qwen_omni", "doubao3": "doubao"}
        voices = [
            {**voice, "provider": providers[voice["provider"]]}
            for voice in value["voices"] if voice["provider"] in providers
        ]
        identities = {(v["provider"], v["voiceType"]) for v in voices}
        if len(identities) != len(voices) or not all(
            any(v["provider"] == p for v in voices) for p in providers.values()
        ):
            raise ValueError("Incomplete or duplicate official catalog")
        for voice in voices:
            for key in ["name", "voiceType", "scene", "language", "languageSummary"]:
                if not isinstance(voice.get(key), str) or not voice[key].strip():
                    raise ValueError(f"Missing voice metadata: {key}")
        return voices
    raise ValueError("Official voiceCatalog payload not found; snapshot unchanged")


def dart_string(value):
    return json.dumps(value, ensure_ascii=False).replace("$", "\\$")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="Previously downloaded official HTML")
    parser.add_argument("--ali-input", type=Path, help="Ali voice table HTML to import by code")
    parser.add_argument("--date", default=datetime.now(timezone.utc).date().isoformat())
    args = parser.parse_args()
    if args.input:
        html = args.input.read_text()
    else:
        with urlopen(SOURCE, timeout=30) as response:
            html = response.read().decode("utf-8")
    voices = catalog_from_html(html)
    ali_path = ROOT / "tool/voice_catalog/ali_media.json"
    if args.ali_input:
        ali_media = ali_media_from_html(args.ali_input.read_text(), voices)
    else:
        ali_media = json.loads(ali_path.read_text())
    media_by_provider = {
        "qwen_omni": ali_media,
        "doubao": json.loads((ROOT / "tool/voice_catalog/doubao_media.json").read_text()),
    }
    for voice in voices:
        item = media_by_provider[voice["provider"]].get(voice["voiceType"], {})
        for field, key in [("trialUrl", "TrialURL"), ("avatarUrl", "Avatar")]:
            value = item.get(key, "")
            if value and (urlparse(value).scheme != "https" or not urlparse(value).netloc):
                raise ValueError(f"Invalid public media URL for {voice['voiceType']}")
            voice[field] = value
    digest = hashlib.sha256(
        json.dumps(voices, ensure_ascii=False, sort_keys=True).encode()
    ).hexdigest()
    lines = [
        "// Generated by python3 tool/update_voice_catalog.py. Do not edit.",
        "part of 'voice_catalog.dart';", "",
        f"const voiceCatalogSource = {dart_string(SOURCE)};",
        f"const voiceCatalogDate = {dart_string(args.date)};",
        f"const voiceCatalogDigest = {dart_string(digest)};", "",
        "const officialVoices = <VoiceOption>[",
    ]
    for voice in voices:
        provider = "qwenOmni" if voice["provider"] == "qwen_omni" else "doubao"
        lines += ["  VoiceOption(", f"    provider: VoiceProvider.{provider},"]
        for field, key in [("id", "voiceType"), ("name", "name"),
                           ("description", "scene"), ("languages", "language"),
                           ("languageSummary", "languageSummary")]:
            lines.append(f"    {field}: {dart_string(voice[key])},")
        for field in ["trialUrl", "avatarUrl"]:
            if voice.get(field):
                lines.append(f"    {field}: {dart_string(voice[field])},")
        lines.append("  ),")
    lines += ["];", ""]
    target = ROOT / "lib/domain/voice_catalog_data.g.dart"
    if args.ali_input:
        ali_path.write_text(json.dumps(ali_media, ensure_ascii=False, indent=2) + "\n")
    target.write_text("\n".join(lines))
    print(f"Updated {len(voices)} realtime voices: {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
