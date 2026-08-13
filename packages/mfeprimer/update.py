#!/usr/bin/env python3

import base64
import json
import os
import re
import subprocess
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent
PACKAGE_NIX = PACKAGE_DIR / "package.nix"
FLAKE_ROOT = PACKAGE_DIR.parents[1]
REPOSITORY = "quwubin/MFEprimer-3.0"
ASSETS = {
    "x86_64-linux": "linux-amd64",
    "aarch64-linux": "linux-arm64",
    "x86_64-darwin": "darwin-amd64",
    "aarch64-darwin": "darwin-arm64",
}


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["CLICOLOR"] = "0"
    env["NO_COLOR"] = "1"
    env["GH_FORCE_TTY"] = "0"
    return subprocess.run(command, check=True, capture_output=True, text=True, env=env)


def sri_hash(digest: str, asset_name: str) -> str:
    match = re.fullmatch(r"sha256:([0-9a-f]{64})", digest)
    if match is None:
        raise ValueError(f"release asset {asset_name} has no valid SHA-256 digest")
    raw = bytes.fromhex(match.group(1))
    return "sha256-" + base64.b64encode(raw).decode()


def version_key(version: str) -> tuple[int, ...]:
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)+", version):
        raise ValueError(f"unexpected version: {version!r}")
    return tuple(int(part) for part in version.split("."))


def main() -> None:
    original = PACKAGE_NIX.read_text()
    current_match = re.search(r'pname = "mfeprimer";\s*version = "([^"]+)";', original)
    if current_match is None:
        raise ValueError(f"could not find current version in {PACKAGE_NIX}")
    current = current_match.group(1)

    release = json.loads(
        run(["gh", "api", f"repos/{REPOSITORY}/releases/latest"]).stdout
    )
    tag = release["tag_name"]
    version = tag.removeprefix("v")
    if tag != f"v{version}":
        raise ValueError(f"unexpected release tag: {tag!r}")
    if version_key(version) < version_key(current):
        raise ValueError(f"refusing to downgrade mfeprimer from {current} to {version}")

    release_assets = {asset["name"]: asset for asset in release["assets"]}
    hashes = {}
    for system, platform in ASSETS.items():
        name = f"mfeprimer-{version}-{platform}.gz"
        asset = release_assets.get(name)
        if asset is None:
            raise ValueError(f"release {tag} does not contain {name}")
        hashes[system] = sri_hash(asset.get("digest", ""), name)

    if version == current and all(
        re.search(
            rf'{re.escape(system)} = \{{.*?hash = "{re.escape(hashes[system])}";',
            original,
            flags=re.DOTALL,
        )
        for system in ASSETS
    ):
        print(f"mfeprimer already at {version}")
        return

    candidate, count = re.subn(
        r'(pname = "mfeprimer";\s*version = ")[^"]+(";)',
        rf"\g<1>{version}\g<2>",
        original,
        count=1,
    )
    if count != 1:
        raise ValueError(f"could not update version in {PACKAGE_NIX}")

    for system, expected_asset in ASSETS.items():
        pattern = (
            rf'({re.escape(system)} = \{{\s*asset = "{re.escape(expected_asset)}";'
            rf'\s*hash = ")[^"]+(";)'
        )
        candidate, count = re.subn(
            pattern,
            rf"\g<1>{hashes[system]}\g<2>",
            candidate,
            count=1,
        )
        if count != 1:
            raise ValueError(f"could not update {system} hash in {PACKAGE_NIX}")

    try:
        PACKAGE_NIX.write_text(candidate)
        subprocess.run(
            ["nix", "build", ".#mfeprimer", "--no-link"],
            cwd=FLAKE_ROOT,
            check=True,
        )
    except BaseException:
        PACKAGE_NIX.write_text(original)
        raise

    print(f"mfeprimer {current} -> {version}")


if __name__ == "__main__":
    main()
