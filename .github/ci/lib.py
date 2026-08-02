import os
import subprocess
from pathlib import Path


def run(
    cmd: list[str],
    *,
    check: bool = True,
    capture: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=check, capture_output=capture, text=True)


def write_output(key: str, value: str) -> None:
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a") as file:
            file.write(f"{key}={value}\n")
    else:
        print(f"{key}={value}")


def nix_eval_raw(attr: str) -> str | None:
    result = run(["nix", "eval", "--raw", attr], check=False, capture=True)
    return result.stdout.strip() if result.returncode == 0 else None
