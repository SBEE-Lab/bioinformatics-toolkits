#!/usr/bin/env python3

import argparse
import logging
import os
import shutil
import signal
import subprocess
import sys
from pathlib import Path

from lib import nix_eval_raw, write_output

log = logging.getLogger(__name__)
DEFAULT_TIMEOUT_SECONDS = 2 * 60 * 60


def nix_update_args(name: str) -> list[str]:
    path = Path("packages") / name / "nix-update-args"
    if not path.exists():
        return []
    return [
        value
        for line in path.read_text().splitlines()
        if (value := line.strip()) and not value.startswith("#")
    ]


def sandbox_works(bwrap: str) -> bool:
    probe = [bwrap, "--ro-bind", "/", "/", "--", "true"]
    if subprocess.run(probe, check=False).returncode == 0:
        return True
    if shutil.which("sudo"):
        subprocess.run(
            [
                "sudo",
                "sysctl",
                "-w",
                "kernel.apparmor_restrict_unprivileged_userns=0",
            ],
            check=False,
        )
    return subprocess.run(probe, check=False).returncode == 0


def sandbox_wrap(command: list[str], name: str) -> list[str]:
    if sys.platform != "linux" or os.environ.get("UPDATE_SANDBOX") == "0":
        return command
    bwrap = shutil.which("bwrap")
    if bwrap is None or not sandbox_works(bwrap):
        log.warning("::warning::bubblewrap unavailable; running updater unsandboxed")
        return command

    root = Path.cwd()
    package_dir = root / "packages" / name
    return [
        bwrap,
        "--ro-bind",
        "/",
        "/",
        "--dev",
        "/dev",
        "--proc",
        "/proc",
        "--tmpfs",
        "/tmp",
        "--dir",
        "/tmp/home",
        "--setenv",
        "HOME",
        "/tmp/home",
        "--setenv",
        "TMPDIR",
        "/tmp",
        "--bind",
        "/nix",
        "/nix",
        "--bind",
        str(package_dir),
        str(package_dir),
        "--chdir",
        str(root),
        "--die-with-parent",
        "--",
        *command,
    ]


def run_streaming(command: list[str], timeout_seconds: int) -> None:
    process = subprocess.Popen(command, start_new_session=True)
    try:
        returncode = process.wait(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        raise SystemExit(
            f"updater timed out after {timeout_seconds} seconds: {command[0]}"
        ) from None
    if returncode != 0:
        raise SystemExit(returncode)


def run_update(name: str) -> None:
    script = Path("packages") / name / "update.py"
    command = (
        [str(script)]
        if script.exists()
        else ["nix-update", "--flake", name, *nix_update_args(name)]
    )
    timeout_seconds = int(
        os.environ.get("UPDATE_TIMEOUT_SECONDS", str(DEFAULT_TIMEOUT_SECONDS))
    )
    run_streaming(sandbox_wrap(command, name), timeout_seconds)


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    name = parser.parse_args().name

    run_update(name)
    changed = (
        subprocess.run(
            ["git", "diff", "--quiet", "origin/main"],
            check=False,
        ).returncode
        != 0
    )
    write_output("updated", str(changed).lower())
    if changed:
        version = nix_eval_raw(f".#packages.x86_64-linux.{name}.version") or "unknown"
        write_output("new_version", version)


if __name__ == "__main__":
    main()
