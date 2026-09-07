#!/usr/bin/env python3
"""Fit the focused Niri window to the available height, preserving its aspect ratio."""

import argparse
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tomllib


def run_command(*command: str) -> str:
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout


def niri_query(name: str):
    return json.loads(run_command("niri", "msg", "--json", name))


def horizontal_bar_reserve(config: dict, connector: str, *identity_fields: str) -> int:
    total = 0
    for name, bar in config["bar"].items():
        if name == "order":
            continue

        # Noctalia uses the first matching monitor override. Identity selectors
        # match complete whitespace-delimited tokens, not arbitrary substrings.
        for table_name, override in bar.get("monitor", {}).items():
            selector = override.get("match", table_name)
            if selector and (
                selector == connector
                or any(
                    re.search(rf"(?<!\S){re.escape(selector)}(?!\S)", field)
                    for field in identity_fields
                )
            ):
                bar = bar | override
                break

        if not bar.get("enabled", True) or not bar.get("reserve_space", True):
            continue
        if bar.get("position", "top") not in {"top", "bottom"}:
            continue

        # All values are logical pixels. Auto-hide does not change reserve_space.
        total += (
            bar.get("thickness", 34)
            + max(0, bar.get("margin_edge", 0))
            + max(0, bar.get("margin_opposite_edge", 0))
        )
    return total


def niri_gaps() -> float:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    try:
        lines = (config_home / "niri" / "layout.kdl").read_text().splitlines()
    except OSError:
        return 0
    for line in lines:
        fields = line.split()
        if len(fields) >= 2 and fields[0] == "gaps":
            return float(fields[1].rstrip(";"))
    return 0


def fit_window(*, dry_run: bool) -> None:
    window = niri_query("focused-window")
    if window is None:
        raise ValueError("no focused window")
    current_width, current_height = window["layout"]["window_size"]
    if not all(
        math.isfinite(value) and value > 0 for value in (current_width, current_height)
    ):
        raise ValueError("focused window has an invalid size")

    connector = next(
        (
            workspace["output"]
            for workspace in niri_query("workspaces")
            if workspace["id"] == window["workspace_id"]
        ),
        None,
    )
    if connector is None:
        raise ValueError("cannot find the window output")
    output = niri_query("outputs")[connector]
    output_height = output["logical"]["height"]
    identity = [output.get(key) or "" for key in ("make", "model", "serial")]

    # Let Noctalia resolve includes, GUI overrides and defaults itself.
    config = tomllib.loads(run_command("noctalia", "config", "export", "full"))
    reserve = horizontal_bar_reserve(config, connector, " ".join(identity), *identity)
    target_height = math.floor(output_height - reserve - 2 * niri_gaps() + 0.5)
    target_width = math.floor(target_height * current_width / current_height)
    if target_height <= 0 or target_width <= 0:
        raise ValueError("calculated an invalid target size")

    if dry_run:
        print(
            f"window={window['id']} output={connector} "
            f"current={current_width:g}x{current_height:g} "
            f"target={target_width}x{target_height}"
        )
        return

    # Address the original window even if focus changes during the queries.
    for dimension, size in (("width", target_width), ("height", target_height)):
        run_command(
            "niri",
            "msg",
            "action",
            f"set-window-{dimension}",
            "--id",
            str(window["id"]),
            str(size),
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="print dimensions without resizing"
    )
    args = parser.parse_args()
    try:
        fit_window(dry_run=args.dry_run)
    except subprocess.CalledProcessError as error:
        detail = error.stderr.strip() or f"exit status {error.returncode}"
        print(
            f"fit-window-to-height: {' '.join(error.cmd)} failed: {detail}",
            file=sys.stderr,
        )
        return 1
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"fit-window-to-height: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
