#!/usr/bin/env python3

import os
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent
PACKAGE_NIX = PACKAGE_DIR / "package.nix"
FLAKE_ROOT = PACKAGE_DIR.parents[1]

sys.path.insert(0, str(FLAKE_ROOT / "scripts"))

from updater import (
    FAKE_HASH,
    find,
    latest_release,
    prefetch_archive,
    replace,
    resolve_fixed_output_hash,
)

OWNER = "genomoncology"
REPO = "biomcp"
FLAKE_ATTR = ".#biomcp"


def main() -> None:
    """Refresh BioMCP from its latest stable GitHub release."""
    os.chdir(FLAKE_ROOT)

    original = PACKAGE_NIX.read_text()
    current = find(
        original,
        r'pname = "biomcp";\s*version = "([^"]*)"',
        PACKAGE_NIX,
    )
    print("biomcp: resolving latest release", flush=True)
    version = latest_release(OWNER, REPO)
    source_url = (
        f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/v{version}.tar.gz"
    )
    source_hash = prefetch_archive(source_url)

    candidate = replace(
        original,
        r'(pname = "biomcp";\s*version = ")[^"]*(")',
        version,
        PACKAGE_NIX,
    )
    candidate = replace(
        candidate,
        r'(repo = "biomcp";.*?hash = ")[^"]*(")',
        source_hash,
        PACKAGE_NIX,
    )
    candidate = replace(
        candidate,
        r'(cargoHash = ")[^"]*(")',
        FAKE_HASH,
        PACKAGE_NIX,
    )

    try:
        print("biomcp: resolving Cargo dependency hash", flush=True)
        cargo_hash = resolve_fixed_output_hash(
            PACKAGE_NIX,
            candidate,
            original,
            FLAKE_ATTR,
        )
        updated = candidate.replace(FAKE_HASH, cargo_hash, 1)
        PACKAGE_NIX.write_text(updated)
    except BaseException:
        PACKAGE_NIX.write_text(original)
        raise

    action = "refreshed" if version == current else f"{current} -> {version}"
    print(f"biomcp {action} (cargo {cargo_hash})")


if __name__ == "__main__":
    main()
