#!/usr/bin/env python3

import argparse
import os

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

    run(["git", "add", "-A"])
    run(["git", "commit", "-m", title])
    run(["git", "push", "--force", "origin", f"HEAD:{branch}"])

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
        run(["gh", "pr", "merge", number, "--auto", "--squash"], check=False)


if __name__ == "__main__":
    main()
