#!/usr/bin/env python3

import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater.command import run
from updater.edit import replace_field
from updater.hash import FAKE_HASH, prefetch_archive, resolve_fixed_output_hash

OWNER = "ncbi"
REPO = "datasets"
FLAKE_ROOT = Path(__file__).parents[2]
FLAKE_ATTR = ".#ncbi-datasets"


def main() -> None:
    os.chdir(FLAKE_ROOT)

    package_dir = Path(__file__).parent
    package_nix = package_dir / "package.nix"
    deps_json = package_dir / "deps.json"
    original_package = package_nix.read_text()
    original_deps = deps_json.read_text()
    text = original_package
    deps = json.loads(original_deps)

    tag = run(
        ["gh", "api", f"repos/{OWNER}/{REPO}/releases/latest", "--jq", ".tag_name"]
    ).stdout.strip()
    version = tag.removeprefix("v")
    commit = run(
        ["gh", "api", f"repos/{OWNER}/{REPO}/commits/{tag}", "--jq", ".sha"]
    ).stdout.strip()

    current_commit = re.search(r'commit = "([^"]*)";', text)
    already_current = current_commit is not None and current_commit.group(1) == commit
    if already_current and FAKE_HASH not in deps.values():
        print(f"{package_dir.name} already at {version} ({commit[:9]})")
        return

    if not already_current:
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

    fake_deps = (
        json.dumps({system: FAKE_HASH for system in sorted(deps)}, indent=2) + "\n"
    )
    package_nix.write_text(text)
    try:
        deps_hash = resolve_fixed_output_hash(
            deps_json,
            fake_deps,
            original_deps,
            FLAKE_ATTR,
        )
        deps_json.write_text(
            json.dumps({system: deps_hash for system in sorted(deps)}, indent=2) + "\n"
        )
        run(["nix", "build", FLAKE_ATTR, "--no-link"], cwd=FLAKE_ROOT)
    except BaseException:
        package_nix.write_text(original_package)
        deps_json.write_text(original_deps)
        raise

    action = "refreshed" if already_current else f"-> {version} ({commit[:9]})"
    print(f"{package_dir.name} {action}; Bazel deps {deps_hash}")


if __name__ == "__main__":
    main()
