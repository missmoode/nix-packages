#!/usr/bin/env python3
"""Update Dusklight's release version and AppImage hashes from GitHub."""

import base64
import json
from pathlib import Path
import re
from urllib.request import Request, urlopen


ARCHES = {"aarch64-linux": "arm64", "x86_64-linux": "x86_64"}
API = "https://api.github.com/repos/TwilitRealm/dusklight/releases/latest"


def release_data(release):
    tag = release["tag_name"]
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        raise ValueError(f"Unexpected Dusklight release tag: {tag}")

    version = tag[1:]
    assets = {a["name"]: a for a in release["assets"]}
    result = {}

    for system, arch in ARCHES.items():
        name = f"Dusklight-v{version}-linux-{arch}.AppImage"
        digest = assets[name]["digest"]
        if not digest or not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
            raise ValueError(f"Missing/invalid SHA256 digest for {name}")
        raw_hash = bytes.fromhex(digest.removeprefix("sha256:"))
        result[system] = {
            "arch": arch,
            "hash": "sha256-" + base64.b64encode(raw_hash).decode("ascii"),
        }

    return {"version": version, "assets": result}


def main():
    request = Request(API, headers={"User-Agent": "nix-packages-dusklight-updater"})
    with urlopen(request, timeout=30) as response:
        release = json.load(response)

    destination = Path(__file__).with_name("release.json")
    new_text = json.dumps(release_data(release), indent=2) + "\n"
    if destination.read_text() == new_text:
        print("Dusklight is already at the latest release.")
    else:
        destination.write_text(new_text)
        print(f"Updated Dusklight to {release['tag_name']}; run nix build -L .#dusklight")


if __name__ == "__main__":
    main()
