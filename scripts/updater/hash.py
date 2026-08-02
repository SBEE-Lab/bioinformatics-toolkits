import re
from pathlib import Path

from .command import run

FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def prefetch_archive(url: str) -> str:
    base32 = run(
        ["nix-prefetch-url", "--unpack", "--type", "sha256", url]
    ).stdout.strip()
    return run(
        ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", base32]
    ).stdout.strip()


def resolve_fixed_output_hash(
    path: Path,
    candidate: str,
    original: str,
    flake_attr: str,
) -> str:
    path.write_text(candidate)
    try:
        result = run(["nix", "build", flake_attr, "--no-link"], check=False)
    except BaseException:
        path.write_text(original)
        raise

    output = result.stdout + result.stderr
    match = re.search(r"got:\s+(sha256-[A-Za-z0-9+/=]+)", output)
    if match is None:
        path.write_text(original)
        raise ValueError(
            f"could not determine the fixed-output hash for {flake_attr}\n{output}"
        )
    return match.group(1)
