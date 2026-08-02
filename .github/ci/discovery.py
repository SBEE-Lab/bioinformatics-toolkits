#!/usr/bin/env python3

import json
import os
import subprocess

from lib import write_output

EXPR = """
ps: builtins.mapAttrs
  (_: pkg: if pkg ? version && !(pkg.passthru.skipUpdate or false) then pkg.version else null)
  ps
"""


def main() -> None:
    requested = os.environ.get("PACKAGES", "").split()
    result = subprocess.run(
        [
            "nix",
            "eval",
            "--json",
            ".#packages.x86_64-linux",
            "--apply",
            EXPR,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    versions: dict[str, str | None] = json.loads(result.stdout)
    matrix = [
        {"name": name, "current_version": version}
        for name, version in sorted(versions.items())
        if version is not None and (not requested or name in requested)
    ]
    write_output("matrix", json.dumps({"include": matrix}, separators=(",", ":")))
    write_output("has-updates", str(bool(matrix)).lower())


if __name__ == "__main__":
    main()
