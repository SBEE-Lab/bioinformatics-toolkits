import re
from pathlib import Path


def find(text: str, pattern: str, path: Path) -> str:
    match = re.search(pattern, text, flags=re.DOTALL)
    if match is None:
        raise ValueError(f"could not find {pattern!r} in {path}")
    return match.group(1)


def replace(text: str, pattern: str, value: str, path: Path) -> str:
    updated, count = re.subn(
        pattern,
        rf"\g<1>{value}\g<2>",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count != 1:
        raise ValueError(f"could not rewrite {pattern!r} in {path}")
    return updated


def replace_field(text: str, key: str, value: str, path: Path) -> str:
    pattern = rf'({re.escape(key)} = ")[^"]*(";)'
    return replace(text, pattern, value, path)
