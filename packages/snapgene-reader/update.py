#!/usr/bin/env python3

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[2] / "scripts"))

from updater import update_github_release

update_github_release(
    Path(__file__).parent,
    owner="Edinburgh-Genome-Foundry",
    repo="SnapGeneReader",
)
