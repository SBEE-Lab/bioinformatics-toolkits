#!/usr/bin/env python3

import argparse
import os
import shutil
import tempfile
from pathlib import Path

from lib import run


def pr_number(branch: str) -> str | None:
    result = run(
        [
            "gh",
            "pr",
            "list",
            "--head",
            branch,
            "--json",
            "number",
            "--jq",
            ".[0].number // empty",
        ],
        capture=True,
    )
    return result.stdout.strip() or None


def changed_paths() -> list[Path]:
    tracked = run(
        ["git", "diff", "--name-only", "-z", "origin/main"],
        capture=True,
    ).stdout
    untracked = run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        capture=True,
    ).stdout
    return sorted({Path(path) for path in (tracked + untracked).split("\0") if path})


def check_confinement(name: str) -> None:
    root = Path("packages") / name
    unexpected = [
        path for path in changed_paths() if path != root and root not in path.parents
    ]
    if unexpected:
        paths = "\n".join(f"  {path}" for path in unexpected)
        raise SystemExit(f"updater changed files outside {root}:\n{paths}")


def copy_package(source: Path, destination: Path) -> None:
    shutil.rmtree(destination)
    shutil.copytree(source, destination, symlinks=True)


def publish_from_clean_clone(name: str, branch: str, title: str) -> None:
    dirty = Path.cwd()
    source = dirty / "packages" / name
    token = os.environ["GH_TOKEN"]
    repository = os.environ["GITHUB_REPOSITORY"]
    url = f"https://x-access-token:{token}@github.com/{repository}.git"

    check_confinement(name)
    with tempfile.TemporaryDirectory(prefix="update-publish-") as temporary:
        clean = Path(temporary) / "repo"
        run(
            [
                "git",
                "clone",
                "--quiet",
                "--depth=1",
                "--branch",
                "main",
                url,
                str(clean),
            ]
        )

        destination = clean / "packages" / name
        copy_package(source, destination)

        os.chdir(clean)
        try:
            run(["git", "config", "user.name", "github-actions[bot]"])
            run(
                [
                    "git",
                    "config",
                    "user.email",
                    "41898282+github-actions[bot]@users.noreply.github.com",
                ]
            )
            run(["git", "checkout", "-B", branch])
            run(["git", "add", "--all", "--", f"packages/{name}"])
            run(["git", "commit", "-m", title])
            run(["git", "push", "--force", "origin", f"HEAD:{branch}"])
        finally:
            os.chdir(dirty)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    parser.add_argument("current_version")
    parser.add_argument("new_version")
    args = parser.parse_args()

    branch = f"update/{args.name}"
    title = f"{args.name}: update to {args.new_version}"
    body = (
        f"Automated update of {args.name} from "
        f"{args.current_version} to {args.new_version}."
    )

    publish_from_clean_clone(args.name, branch, title)

    number = pr_number(branch)
    if number:
        run(["gh", "pr", "edit", number, "--title", title, "--body", body])
    else:
        run(
            [
                "gh",
                "pr",
                "create",
                "--base",
                "main",
                "--head",
                branch,
                "--title",
                title,
                "--body",
                body,
                "--label",
                "auto-merge",
            ]
        )
        number = pr_number(branch)

    if os.environ.get("AUTO_MERGE") == "true" and number:
        run(["gh", "pr", "merge", number, "--auto", "--merge"], check=False)


if __name__ == "__main__":
    main()
