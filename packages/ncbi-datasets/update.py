#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater.command import run
from updater.edit import replace_field
from updater.hash import FAKE_HASH, prefetch_archive

OWNER = "ncbi"
REPO = "datasets"


def main() -> None:
    package_dir = Path(__file__).parent
    package_nix = package_dir / "package.nix"
    deps_json = package_dir / "deps.json"
    text = package_nix.read_text()

    tag = run(
        ["gh", "api", f"repos/{OWNER}/{REPO}/releases/latest", "--jq", ".tag_name"]
    ).stdout.strip()
    version = tag.removeprefix("v")
    commit = run(
        ["gh", "api", f"repos/{OWNER}/{REPO}/commits/{tag}", "--jq", ".sha"]
    ).stdout.strip()

    current_commit = re.search(r'commit = "([^"]*)";', text)
    if current_commit is not None and current_commit.group(1) == commit:
        print(f"{package_dir.name} already at {version} ({commit[:9]})")
        return

    source_hash = prefetch_archive(
        f"https://github.com/{OWNER}/{REPO}/archive/{commit}.tar.gz"
    )
    darwin_hash = prefetch_archive(
        f"https://github.com/{OWNER}/{REPO}/releases/download/{tag}/darwin-arm64.cli.package.zip"
    )
    text = replace_field(text, "version", version, package_nix)
    text = replace_field(text, "commit", commit, package_nix)
    text, source_hash_replacements = re.subn(
        r'(src = fetchFromGitHub \{.*?hash = ")[^"]*(";\n    \};)',
        rf"\1{source_hash}\2",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if source_hash_replacements != 1:
        raise ValueError(f"could not rewrite source hash in {package_nix}")
    text, darwin_hash_replacements = re.subn(
        r'(darwinPackage = stdenv\.mkDerivation \{.*?hash = ")[^"]*(";\n      stripRoot = false;)',
        rf"\1{darwin_hash}\2",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if darwin_hash_replacements != 1:
        raise ValueError(f"could not rewrite Darwin binary hash in {package_nix}")
    deps = json.loads(deps_json.read_text())
    deps_json.write_text(
        json.dumps({system: FAKE_HASH for system in sorted(deps)}, indent=2) + "\n"
    )
    package_nix.write_text(text)
    print(f"{package_dir.name} -> {version} ({commit[:9]}); Bazel deps hashes reset")


if __name__ == "__main__":
    main()
