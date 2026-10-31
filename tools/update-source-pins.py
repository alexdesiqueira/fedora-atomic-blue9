#!/usr/bin/env python3
"""Refresh reviewed source revisions and checksums used by image scripts."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
GITHUB_API = "https://api.github.com"
GIT_SOURCES = (
    ("files/scripts/01-main.sh", "APPMENU", "rilian-la-te/vala-panel-appmenu"),
    ("files/scripts/10-platinum9.sh", "PLATINUM9", "timnetworks/Platinum9"),
    ("files/scripts/11-b00merang.sh", "MACOS9", "B00merang-Project/Mac-OS-9"),
    ("files/scripts/20-retrosmart-cursors.sh", "RETROSMART", "mdomlop/retrosmart-x11-cursors"),
)


def request(url: str):
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "blue9-pin-updater"}
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    return urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=120)


def json_request(url: str):
    with request(url) as response:
        return json.load(response)


def sha256_url(url: str) -> str:
    digest = hashlib.sha256()
    with tempfile.TemporaryFile() as output, request(url) as response:
        while chunk := response.read(1024 * 1024):
            digest.update(chunk)
            output.write(chunk)
    return digest.hexdigest()


def replace_pin(text: str, name: str, value: str) -> str:
    updated, count = re.subn(
        rf'^(readonly {re.escape(name)}=")[^"]+(".*)$',
        rf'\g<1>{value}\2', text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError(f"could not find exactly one {name}")
    return updated


def main() -> None:
    updates: dict[Path, str] = {}
    for relative_path, prefix, repository in GIT_SOURCES:
        metadata = json_request(f"{GITHUB_API}/repos/{repository}/commits/HEAD")
        commit = metadata["sha"]
        archive_url = f"https://github.com/{repository}/archive/{commit}.tar.gz"
        checksum = sha256_url(archive_url)
        path = ROOT / relative_path
        text = path.read_text(encoding="utf-8")
        text = replace_pin(text, f"{prefix}_COMMIT", commit)
        text = replace_pin(text, f"{prefix}_SHA256", checksum)
        updates[path] = text
        print(f"{repository}: {commit} sha256:{checksum}")

    release = json_request(f"{GITHUB_API}/repos/ryanoasis/nerd-fonts/releases/latest")
    version = release["tag_name"].removeprefix("v")
    asset = next(item for item in release["assets"] if item["name"] == "CascadiaMono.zip")
    checksum = sha256_url(asset["browser_download_url"])
    font_path = ROOT / "files/scripts/22-fonts.sh"
    font_text = font_path.read_text(encoding="utf-8")
    font_text = replace_pin(font_text, "CASCADIA_VERSION", version)
    font_text = replace_pin(font_text, "CASCADIA_SHA256", checksum)
    updates[font_path] = font_text
    print(f"ryanoasis/nerd-fonts: v{version} sha256:{checksum}")

    for path, text in updates.items():
        path.write_text(text, encoding="utf-8")

    print("Pins updated. Review upstream changes and run the full test suite before committing.")


if __name__ == "__main__":
    main()
