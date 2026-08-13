#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent
PACKAGE_NIX = PACKAGE_DIR / "package.nix"
FLAKE_ROOT = PACKAGE_DIR.parents[1]

sys.path.insert(0, str(FLAKE_ROOT / "scripts"))

from updater import find, latest_release, prefetch_archive, replace  # noqa: E402

OWNER = "Edinburgh-Genome-Foundry"
REPO = "DnaFeaturesViewer"


def main() -> None:
    original = PACKAGE_NIX.read_text()
    current = find(
        original,
        r'pname = "dna-features-viewer";\s*version = "([^"]*)"',
        PACKAGE_NIX,
    )
    version = latest_release(OWNER, REPO)

    if version == current:
        print(f"dna-features-viewer already at {version}")
        return

    source_hash = prefetch_archive(
        f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/v{version}.tar.gz"
    )
    candidate = replace(
        original,
        r'(pname = "dna-features-viewer";\s*version = ")[^"]*(")',
        version,
        PACKAGE_NIX,
    )
    candidate = replace(
        candidate,
        r'(repo = "DnaFeaturesViewer";.*?hash = ")[^"]*(")',
        source_hash,
        PACKAGE_NIX,
    )

    try:
        PACKAGE_NIX.write_text(candidate)
        subprocess.run(
            ["nix", "build", ".#dna-features-viewer", "--no-link"],
            cwd=FLAKE_ROOT,
            check=True,
        )
    except BaseException:
        PACKAGE_NIX.write_text(original)
        raise

    print(f"dna-features-viewer {current} -> {version}")


if __name__ == "__main__":
    main()
