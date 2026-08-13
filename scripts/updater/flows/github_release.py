import sys
from pathlib import Path

from ..command import run
from ..edit import find, replace_field
from ..github import latest_release
from ..hash import prefetch_archive


def update_github_release(
    package_dir: Path,
    owner: str,
    repo: str,
    *,
    tag_prefix: str = "v",
) -> None:
    package_nix = package_dir / "package.nix"
    original = package_nix.read_text()
    current = find(original, r'version = "([^"]*)"', package_nix)
    version = latest_release(owner, repo)

    if version == current:
        print(f"{package_dir.name} already at {version}")
        return

    tag = f"{tag_prefix}{version}"
    source_hash = prefetch_archive(
        f"https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.tar.gz"
    )
    candidate = replace_field(original, "version", version, package_nix)
    candidate = replace_field(candidate, "hash", source_hash, package_nix)

    package_nix.write_text(candidate)
    try:
        result = run(
            ["nix", "build", f".#{package_dir.name}", "--no-link"],
            cwd=package_dir.parents[1],
            check=False,
        )
        if result.returncode != 0:
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
            raise RuntimeError(f"updated {package_dir.name} failed to build")
    except BaseException:
        package_nix.write_text(original)
        raise

    print(f"{package_dir.name} {current} -> {version}")
