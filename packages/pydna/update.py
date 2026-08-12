#!/usr/bin/env python3

import base64
import json
import re
import subprocess
import urllib.request
from pathlib import Path
from typing import Any

PACKAGE_DIR = Path(__file__).parent
PACKAGE_NIX = PACKAGE_DIR / "package.nix"
FLAKE_ROOT = PACKAGE_DIR.parents[1]
PYPI_JSON = "https://pypi.org/pypi/pydna/json"

# These requirements describe the upstream dependency contract reviewed when
# packaging the local helper derivations. Do not solve changed constraints in
# the updater: fail so that the package expressions can be reviewed together.
EXPECTED_REQUIREMENTS = {
    "biopython": "<2.0,>=1.87",
    "cai2": ">=1.0.5",
    "opencloning-linkml": "<2,>=1",
    "seguid": ">=0.0.5",
    "sgffp": ">=0.18.0",
}


def normalize_name(name: str) -> str:
    """Normalize a Python distribution name according to PEP 503."""
    return re.sub(r"[-_.]+", "-", name).lower()


def requirement_specs(requirements: list[str]) -> dict[str, list[str]]:
    """Extract distribution names and specifiers without resolving versions."""
    specs: dict[str, list[str]] = {}
    for raw in requirements:
        requirement, _, _marker = raw.partition(";")
        match = re.fullmatch(
            r"\s*([A-Za-z0-9][A-Za-z0-9._-]*)(?:\[[^]]*\])?\s*(.*?)\s*",
            requirement,
        )
        if match is None:
            raise ValueError(f"could not parse pydna requirement: {raw!r}")
        name = normalize_name(match.group(1))
        specs.setdefault(name, []).append(match.group(2))
    return specs


def validate_dependency_contract(release: dict[str, Any]) -> None:
    """Reject dependency changes that require a package review."""
    raw_requirements = release.get("info", {}).get("requires_dist")
    if not isinstance(raw_requirements, list) or not all(
        isinstance(item, str) for item in raw_requirements
    ):
        raise TypeError("PyPI metadata has no valid requires_dist list")

    actual = requirement_specs(raw_requirements)
    changes = [
        f"{name}: expected {[expected]!r}, got {actual.get(name, [])!r}"
        for name, expected in EXPECTED_REQUIREMENTS.items()
        if actual.get(name) != [expected]
    ]
    if changes:
        details = "\n".join(changes)
        raise ValueError(
            "pydna dependency metadata changed; review the packaged dependency "
            f"pins manually:\n{details}"
        )


def sri_hash(hex_digest: str) -> str:
    """Convert a hexadecimal SHA-256 digest to an SRI hash."""
    return "sha256-" + base64.b64encode(bytes.fromhex(hex_digest)).decode()


def replace_once(text: str, pattern: str, replacement: str) -> str:
    """Replace exactly one package.nix field."""
    updated, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise ValueError(f"expected one match for {pattern!r}, found {count}")
    return updated


def validate_packages() -> None:
    """Build the default package and the variant containing every extra."""
    subprocess.run(
        ["nix", "build", ".#pydna", "--no-link"],
        cwd=FLAKE_ROOT,
        check=True,
    )
    flake_url = json.dumps(f"path:{FLAKE_ROOT}")
    expression = (
        f"let flake = builtins.getFlake {flake_url}; "
        "in flake.packages.x86_64-linux.pydna.override "
        "{ withAllExtras = true; }"
    )
    subprocess.run(
        ["nix", "build", "--impure", "--no-link", "--expr", expression],
        cwd=FLAKE_ROOT,
        check=True,
    )


def main() -> None:
    """Update pydna after checking its reviewed dependency contract."""
    with urllib.request.urlopen(PYPI_JSON) as response:
        release = json.load(response)

    validate_dependency_contract(release)

    version = release["info"]["version"]
    source = next(
        (file for file in release["urls"] if file["packagetype"] == "sdist"),
        None,
    )
    if source is None:
        raise ValueError(f"pydna {version} has no source distribution")
    source_hash = sri_hash(source["digests"]["sha256"])

    original = PACKAGE_NIX.read_text()
    current_match = re.search(r'pname = "pydna";\s*version = "([^"]+)";', original)
    if current_match is None:
        raise ValueError(f"could not find pydna version in {PACKAGE_NIX}")
    current = current_match.group(1)

    updated = replace_once(
        original,
        r'(pname = "pydna";\s*version = ")[^"]+(";)',
        rf"\g<1>{version}\g<2>",
    )
    updated = replace_once(
        updated,
        r'(inherit \(finalAttrs\) pname version;\s*hash = ")[^"]+(";)',
        rf"\g<1>{source_hash}\g<2>",
    )

    if updated == original:
        print(f"pydna already at {version}; dependency contract unchanged")
        return

    try:
        PACKAGE_NIX.write_text(updated)
        validate_packages()
    except BaseException:
        PACKAGE_NIX.write_text(original)
        raise

    print(f"pydna {current} -> {version}")


if __name__ == "__main__":
    main()
