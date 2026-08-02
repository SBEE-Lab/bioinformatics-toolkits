#!/usr/bin/env python3

import argparse
import subprocess
import sys
from pathlib import Path

from lib import nix_eval_raw, write_output


def nix_update_args(name: str) -> list[str]:
    path = Path("packages") / name / "nix-update-args"
    if not path.exists():
        return []
    return [
        value
        for line in path.read_text().splitlines()
        if (value := line.strip()) and not value.startswith("#")
    ]


def run_update(name: str) -> None:
    script = Path("packages") / name / "update.py"
    command = (
        [str(script)]
        if script.exists()
        else ["nix-update", "--flake", name, *nix_update_args(name)]
    )
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    sys.stdout.write(result.stdout)
    if result.returncode != 0:
        raise SystemExit(result.returncode)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    name = parser.parse_args().name

    run_update(name)
    changed = bool(
        subprocess.run(
            ["git", "status", "--porcelain"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    )
    write_output("updated", str(changed).lower())
    if changed:
        version = nix_eval_raw(f".#packages.x86_64-linux.{name}.version") or "unknown"
        write_output("new_version", version)


if __name__ == "__main__":
    main()
