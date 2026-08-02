#!/usr/bin/env python3

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater import (
    FAKE_HASH,
    find,
    latest_release,
    prefetch_archive,
    replace,
    resolve_fixed_output_hash,
)

OWNER = "biotite-dev"
REPO = "biotite"
PACKAGE_NIX = Path(__file__).parent / "package.nix"


def main() -> None:
    original = PACKAGE_NIX.read_text()
    current = find(
        original,
        r'pname = "biotite";\s*version = "([^"]*)"',
        PACKAGE_NIX,
    )
    version = latest_release(OWNER, REPO)
    if version == current:
        print(f"biotite already at {version}")
        return

    source_hash = prefetch_archive(
        f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/v{version}.tar.gz"
    )
    candidate = replace(
        original,
        r'(pname = "biotite";\s*version = ")[^"]*(")',
        version,
        PACKAGE_NIX,
    )
    candidate = replace(
        candidate,
        r'(repo = "biotite";.*?hash = ")[^"]*(")',
        source_hash,
        PACKAGE_NIX,
    )
    candidate = replace(
        candidate,
        r'(cargoDeps = rustPlatform\.fetchCargoVendor \{.*?hash = ")[^"]*(")',
        FAKE_HASH,
        PACKAGE_NIX,
    )
    vendor_hash = resolve_fixed_output_hash(
        PACKAGE_NIX,
        candidate,
        original,
        ".#biotite",
    )
    PACKAGE_NIX.write_text(candidate.replace(FAKE_HASH, vendor_hash, 1))
    print(f"biotite -> {version} (vendor {vendor_hash})")


if __name__ == "__main__":
    main()
