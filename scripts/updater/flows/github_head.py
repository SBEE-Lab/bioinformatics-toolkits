from collections.abc import Callable
from pathlib import Path

from ..edit import find, replace_field
from ..github import latest_commit
from ..hash import prefetch_archive


def update_github_head(
    package_dir: Path,
    owner: str,
    repo: str,
    version_from_date: Callable[[str], str],
) -> None:
    package_nix = package_dir / "package.nix"
    text = package_nix.read_text()
    current_rev = find(text, r'rev = "([^"]*)"', package_nix)
    sha, date = latest_commit(owner, repo)

    if sha == current_rev:
        print(f"{package_dir.name} already at {sha[:9]} ({date})")
        return

    source_hash = prefetch_archive(
        f"https://github.com/{owner}/{repo}/archive/{sha}.tar.gz"
    )
    version = version_from_date(date)
    text = replace_field(text, "version", version, package_nix)
    text = replace_field(text, "rev", sha, package_nix)
    text = replace_field(text, "hash", source_hash, package_nix)
    package_nix.write_text(text)
    print(f"{package_dir.name} -> {version} ({sha[:9]})")
