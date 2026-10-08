"""The bar payload that collects everything and prints one JSON line"""

import json

from checks import SECTIONS, safe_rows
from const import BLANK_ROW, Row, UPDATE_SOURCES
from updates import freshen_updates
from util import format_rows, overall_alt


def main() -> None:
    """Health paints the tooltip and the alt while the label counts cached pending updates"""
    rows: list[Row] = []
    for index, section in enumerate(SECTIONS):
        if index:
            rows.append(BLANK_ROW)
        rows.extend(safe_rows(section))
    alt = overall_alt(rows)
    updates = freshen_updates()
    blind = updates is None or len(updates["missing"]) == len(UPDATE_SOURCES)
    payload = {
        "text": "0" if blind else str(len(updates["records"])),
        "alt": alt,
        "tooltip": format_rows(rows),
    }
    print(json.dumps(payload))
