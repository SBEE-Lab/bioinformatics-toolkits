import json

from .command import run


def latest_release(owner: str, repo: str) -> str:
    result = run(["gh", "api", f"repos/{owner}/{repo}/releases/latest"])
    return str(json.loads(result.stdout)["tag_name"]).lstrip("v")


def latest_commit(owner: str, repo: str) -> tuple[str, str]:
    repository = json.loads(run(["gh", "api", f"repos/{owner}/{repo}"]).stdout)
    branch = repository["default_branch"]
    commit = json.loads(
        run(["gh", "api", f"repos/{owner}/{repo}/commits/{branch}"]).stdout
    )
    return commit["sha"], commit["commit"]["committer"]["date"][:10]
