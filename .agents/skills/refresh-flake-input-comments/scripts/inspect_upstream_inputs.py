#!/usr/bin/env python3
"""Render non-trivial upstream input trees for a locked Nix flake."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


JsonObject = dict[str, Any]


def metadata(reference: str, *, offline: bool) -> JsonObject:
    command = [
        "nix",
        "flake",
        "metadata",
        "--json",
        "--no-write-lock-file",
    ]
    if offline:
        command.append("--offline")
    command.append(reference)

    result = subprocess.run(command, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(message or f"metadata failed for {reference}")

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"invalid metadata JSON for {reference}: {error}") from error


def locked_reference(node: JsonObject) -> str:
    locked = node.get("locked", {})
    kind = locked.get("type")
    revision = locked.get("rev")

    if kind == "github":
        return f"github:{locked['owner']}/{locked['repo']}/{revision}"
    if kind == "gitlab":
        return f"gitlab:{locked['owner']}/{locked['repo']}/{revision}"
    if kind == "sourcehut":
        return f"sourcehut:{locked['owner']}/{locked['repo']}/{revision}"
    if kind == "git":
        separator = "&" if "?" in locked["url"] else "?"
        return f"git+{locked['url']}{separator}rev={revision}"
    if kind == "path":
        return f"path:{locked['path']}"

    raise RuntimeError(f"unsupported locked input type: {kind!r}")


def is_trivial_nixpkgs(node: JsonObject) -> bool:
    locked = node.get("locked", {})
    original = node.get("original", {})
    repository = locked.get("repo") or original.get("repo")
    return repository == "nixpkgs" and not node.get("inputs")


def render_tree(name: str, upstream: JsonObject) -> list[str]:
    locks = upstream.get("locks")
    if not locks:
        return [name]

    nodes: JsonObject = locks.get("nodes", {})
    root_id = locks.get("root", "root")
    root = nodes.get(root_id, {})
    seen: dict[str, str] = {}
    lines = [name]

    def walk(inputs: JsonObject, prefix: str, parent_path: str) -> None:
        edges = list(inputs.items())
        for index, (edge_name, target) in enumerate(edges):
            last = index == len(edges) - 1
            connector = "└── " if last else "├── "
            continuation = "    " if last else "│   "
            path = f"{parent_path}/{edge_name}"
            label = edge_name

            if isinstance(target, list):
                shared_path = "/".join([name, *target])
                lines.append(f"{prefix}{connector}{label} (shared with {shared_path})")
                continue

            child_id = str(target)
            if child_id in seen:
                lines.append(
                    f"{prefix}{connector}{label} (shared with {seen[child_id]})"
                )
                continue

            child = nodes.get(child_id, {})
            if child.get("flake") is False:
                label += " (source only)"
            elif edge_name == "nixpkgs":
                repository = child.get("original", {}).get("repo")
                if repository == "nixpkgs.lib":
                    label += " (nixpkgs.lib)"
            lines.append(f"{prefix}{connector}{label}")
            seen[child_id] = path

            child_inputs = child.get("inputs", {})
            if child_inputs:
                walk(child_inputs, prefix + continuation, path)

    walk(root.get("inputs", {}), "", name)
    return lines


def comment_block(name: str, tree: list[str]) -> str:
    lines = ["# Upstream inputs:", *[f"# {line}" for line in tree]]
    return "\n".join(lines)


def normalize_flake_path(value: str) -> str:
    path = Path(value)
    if path.name == "flake.nix":
        path = path.parent
    if path.exists():
        return str(path.resolve())
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Render non-trivial root input graphs from exact locked revisions."
        )
    )
    parser.add_argument("--flake", default=".", help="flake directory or flake.nix")
    parser.add_argument(
        "--input",
        action="append",
        dest="inputs",
        help="render only this root input; repeat to select more than one",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="forbid fetching missing upstream metadata",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit a JSON mapping from root input names to tree lines",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    flake = normalize_flake_path(args.flake)

    try:
        local = metadata(flake, offline=args.offline)
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    locks = local.get("locks", {})
    nodes: JsonObject = locks.get("nodes", {})
    root_id = locks.get("root", "root")
    root_inputs: JsonObject = nodes.get(root_id, {}).get("inputs", {})
    selected = set(args.inputs or root_inputs)
    unknown = selected.difference(root_inputs)
    if unknown:
        print(
            f"error: unknown root inputs: {', '.join(sorted(unknown))}", file=sys.stderr
        )
        return 2

    rendered: dict[str, list[str]] = {}
    failures = 0
    skipped: set[str] = set()

    for name, target in root_inputs.items():
        if isinstance(target, list):
            continue
        node = nodes.get(str(target), {})
        if node.get("flake") is False or is_trivial_nixpkgs(node):
            skipped.add(name)

    for name, target in root_inputs.items():
        if name not in selected:
            continue

        if isinstance(target, list):
            if target and target[0] in skipped:
                continue
            destination = "/".join(target)
            rendered[name] = [f"{name} (local alias of {destination})"]
            continue

        node = nodes.get(str(target), {})
        if name in skipped:
            continue

        try:
            reference = locked_reference(node)
            upstream = metadata(reference, offline=args.offline)
            rendered[name] = render_tree(name, upstream)
        except (KeyError, RuntimeError) as error:
            failures += 1
            message = " ".join(str(error).splitlines())
            rendered[name] = [f"{name} (metadata unavailable: {message})"]

    if args.json:
        print(json.dumps(rendered, indent=2, ensure_ascii=False))
    else:
        blocks = [comment_block(name, tree) for name, tree in rendered.items()]
        if blocks:
            print("\n\n".join(blocks))

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
