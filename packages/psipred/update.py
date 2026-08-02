#!/usr/bin/env python3

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater import update_github_head

update_github_head(
    Path(__file__).parent,
    owner="psipred",
    repo="psipred",
    version_from_date=lambda date: f"4.0-unstable-{date}",
)
