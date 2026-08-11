#!/usr/bin/env python3

import subprocess
import sys
import tarfile
import tempfile
import urllib.request
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
PACKAGE_DIR = Path(__file__).parent
PACKAGE_NIX = PACKAGE_DIR / "package.nix"
CARGO_LOCK = PACKAGE_DIR / "Cargo.lock"


def generate_lockfile(source_url: str) -> bytes:
    with tempfile.TemporaryDirectory() as temporary_directory:
        temporary = Path(temporary_directory)
        archive = temporary / "source.tar.gz"
        urllib.request.urlretrieve(source_url, archive)
        with tarfile.open(archive) as source_archive:
            source_archive.extractall(temporary, filter="data")
        source = next(path for path in temporary.iterdir() if path.is_dir())
        subprocess.run(
            [
                "cargo",
                "generate-lockfile",
                "--manifest-path",
                str(source / "Cargo.toml"),
            ],
            check=True,
        )
        return (source / "Cargo.lock").read_bytes()


def main() -> None:
    original = PACKAGE_NIX.read_text()
    current = find(
        original,
        r'pname = "biotite";\s*version = "([^"]*)"',
        PACKAGE_NIX,
    )
    version = latest_release(OWNER, REPO)
    source_url = (
        f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/v{version}.tar.gz"
    )
    source_hash = prefetch_archive(source_url)
    lockfile = generate_lockfile(source_url)
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

    previous_lockfile = CARGO_LOCK.read_bytes() if CARGO_LOCK.exists() else None
    CARGO_LOCK.write_bytes(lockfile)
    try:
        vendor_hash = resolve_fixed_output_hash(
            PACKAGE_NIX,
            candidate,
            original,
            ".#biotite",
        )
    except BaseException:
        if previous_lockfile is None:
            CARGO_LOCK.unlink(missing_ok=True)
        else:
            CARGO_LOCK.write_bytes(previous_lockfile)
        raise

    PACKAGE_NIX.write_text(candidate.replace(FAKE_HASH, vendor_hash, 1))
    action = "refreshed" if version == current else f"{current} -> {version}"
    print(f"biotite {action} (vendor {vendor_hash})")


if __name__ == "__main__":
    main()
