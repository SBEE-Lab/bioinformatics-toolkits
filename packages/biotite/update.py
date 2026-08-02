#!/usr/bin/env python3
"""Update biotite's version, source hash, and vendored Cargo hash."""

import json
import re
import subprocess
import sys
from pathlib import Path

OWNER = "biotite-dev"
REPO = "biotite"
PKG = Path("packages/biotite")
NIX = PKG / "default.nix"
FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def sh(cmd: list[str]) -> str:
    return subprocess.run(
        cmd, check=True, text=True, capture_output=True
    ).stdout.strip()


def latest_version() -> str:
    release = json.loads(sh(["gh", "api", f"repos/{OWNER}/{REPO}/releases/latest"]))
    return release["tag_name"].lstrip("v")


def prefetch_hash(tag: str) -> str:
    url = f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/{tag}.tar.gz"
    base32 = sh(["nix-prefetch-url", "--unpack", "--type", "sha256", url])
    return sh(["nix", "hash", "to-sri", "--type", "sha256", base32])


def prefetch_vendor_hash(text: str, original_text: str) -> str:
    """Build with a fake hash and return fetchCargoVendor's expected hash."""
    NIX.write_text(text)
    result = subprocess.run(
        ["nix", "build", ".#biotite", "--no-link"],
        text=True,
        capture_output=True,
    )
    output = result.stdout + result.stderr
    match = re.search(r"got:\s+(sha256-[A-Za-z0-9+/=]+)", output)
    if match is None:
        NIX.write_text(original_text)
        sys.stderr.write(output)
        sys.exit("could not determine the biotite vendor hash")
    return match.group(1)


def replace_biotite_field(text: str, pattern: str, value: str) -> str:
    new_text, n = re.subn(
        pattern, rf"\g<1>{value}\g<2>", text, count=1, flags=re.DOTALL
    )
    if n != 1:
        sys.exit(f"could not rewrite {pattern!r} in {NIX}")
    return new_text


def main() -> None:
    original_text = NIX.read_text()
    text = original_text
    current = re.search(r'pname = "biotite";\s*version = "([^"]*)"', text)
    if current is None:
        sys.exit(f"no biotite version field in {NIX}")

    version = latest_version()
    if version == current.group(1):
        print(f"biotite already at {version}")
        return

    sri = prefetch_hash(f"v{version}")
    text = replace_biotite_field(
        text, r'(pname = "biotite";\s*version = ")[^"]*(")', version
    )
    text = replace_biotite_field(text, r'(repo = "biotite";.*?hash = ")[^"]*(")', sri)
    text = replace_biotite_field(
        text,
        r'(cargoDeps = rustPlatform\.fetchCargoVendor \{.*?hash = ")[^"]*(")',
        FAKE_HASH,
    )
    vendor_hash = prefetch_vendor_hash(text, original_text)
    text = text.replace(FAKE_HASH, vendor_hash, 1)
    NIX.write_text(text)

    print(f"biotite -> {version} (vendor {vendor_hash})")


if __name__ == "__main__":
    main()
