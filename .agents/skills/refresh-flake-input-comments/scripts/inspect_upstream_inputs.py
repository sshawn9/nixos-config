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


def nix_json(*arguments: str) -> Any:
    result = subprocess.run(
        ["nix", *arguments, "--json"], capture_output=True, text=True
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Nix command failed")
    return json.loads(result.stdout)


def metadata(reference: str, *, offline: bool, no_update: bool = False) -> JsonObject:
    # Combining these flags allows in-memory lock updates in Nix.
    flags = ["--no-update-lock-file" if no_update else "--no-write-lock-file"]
    if offline:
        flags.append("--offline")
    return nix_json("flake", "metadata", reference, *flags)


def locked_reference(node: JsonObject) -> str:
    literal = json.dumps(json.dumps(node["locked"])).replace("${", r"\${")
    return nix_json(
        "eval", "--expr", f"builtins.flakeRefToString (builtins.fromJSON {literal})"
    )


def is_trivial_nixpkgs(node: JsonObject) -> bool:
    locked = node.get("locked", {})
    original = node.get("original", {})
    repository = locked.get("repo") or original.get("repo")
    return repository == "nixpkgs" and not node.get("inputs")


def resolve_input(
    nodes: JsonObject,
    root_id: str,
    target: str | list[str],
    resolving: frozenset[tuple[str, ...]] = frozenset(),
) -> JsonObject:
    if isinstance(target, str):
        return nodes[target]

    path = tuple(target)
    if path in resolving:
        raise RuntimeError(f"cyclic follows: {'/'.join(path)}")
    node = nodes[root_id]
    for name in path:
        node = resolve_input(
            nodes, root_id, node.get("inputs", {})[name], resolving | {path}
        )
    return node


def render_tree(name: str, upstream: JsonObject) -> list[str]:
    locks = upstream.get("locks") or {}
    nodes: JsonObject = locks.get("nodes", {})
    seen: dict[str, str] = {}
    lines = [name]

    def walk(inputs: JsonObject, prefix: str, parent_path: str) -> None:
        for index, (edge_name, target) in enumerate(inputs.items()):
            last = index == len(inputs) - 1
            connector = "└── " if last else "├── "
            continuation = "    " if last else "│   "
            path = f"{parent_path}/{edge_name}"
            label = edge_name
            shared = (
                "/".join([name, *target])
                if isinstance(target, list)
                else seen.get(target)
            )
            if shared:
                label += f" (shared with {shared})"
            else:
                child = nodes[target]
                seen[target] = path
                if child.get("flake") is False:
                    label += " (source only)"
                elif (
                    edge_name == "nixpkgs"
                    and child.get("original", {}).get("repo") == "nixpkgs.lib"
                ):
                    label += " (nixpkgs.lib)"
            lines.append(f"{prefix}{connector}{label}")
            if not shared:
                walk(child.get("inputs", {}), prefix + continuation, path)

    root = nodes.get(locks.get("root", "root"), {})
    walk(root.get("inputs", {}), "", name)
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flake", default=".", help="flake directory or flake.nix")
    parser.add_argument("--input", action="append", help="root input; repeatable")
    parser.add_argument("--offline", action="store_true", help="reuse cached metadata")
    args = parser.parse_args()
    path = Path(args.flake)
    if path.name == "flake.nix":
        path = path.parent
    flake = str(path.resolve()) if path.exists() else args.flake

    try:
        local = metadata(flake, offline=args.offline, no_update=True)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    locks = local.get("locks", {})
    nodes: JsonObject = locks.get("nodes", {})
    root_id = locks.get("root", "root")
    root_inputs: JsonObject = nodes.get(root_id, {}).get("inputs", {})
    selected = set(args.input or root_inputs)
    unknown = selected.difference(root_inputs)
    if unknown:
        print(
            f"error: unknown root inputs: {', '.join(sorted(unknown))}", file=sys.stderr
        )
        return 2

    blocks: list[str] = []
    failures = 0

    for name, target in root_inputs.items():
        if name not in selected:
            continue

        try:
            node = resolve_input(nodes, root_id, target)
            if node.get("flake") is False or is_trivial_nixpkgs(node):
                continue

            if isinstance(target, list):
                destination = "/".join(target) or "."
                tree = [f"{name} (local alias of {destination})"]
            else:
                reference = locked_reference(node)
                upstream = metadata(reference, offline=args.offline)
                tree = render_tree(name, upstream)
            blocks.append(
                "# Upstream inputs:\n" + "\n".join(f"# {line}" for line in tree)
            )
        except (KeyError, OSError, ValueError, RuntimeError) as error:
            failures += 1
            print(f"error: {name}: {error}", file=sys.stderr)

    if blocks:
        print("\n\n".join(blocks))

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
