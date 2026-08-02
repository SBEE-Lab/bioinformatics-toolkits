#!/usr/bin/env python3

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater import update_github_head

update_github_head(
    Path(__file__).parent,
    owner="pylelab",
    repo="USalign",
    version_from_date=lambda date: date.replace("-", ""),
)
