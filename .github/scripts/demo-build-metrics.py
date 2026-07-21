#!/usr/bin/env python3

import argparse
import html
import json
import subprocess
from pathlib import Path


def run(*args: str) -> str:
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def check_installable(flake: str, system: str, target: str) -> str:
    flake_path = Path(flake)
    if (
        not flake_path.is_absolute()
        and not flake.startswith(".")
        and flake_path.exists()
    ):
        flake = f"./{flake}"
    return f"{flake}#checks.{json.dumps(system)}.{json.dumps(target)}"


def format_size(size: int | None) -> str:
    if size is None:
        return "—"
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.2f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    raise AssertionError("unreachable")


def summarize(args: argparse.Namespace) -> None:
    errors = []
    results = []
    result_path = Path(args.result)
    if result_path.exists():
        try:
            results = json.loads(result_path.read_text(encoding="utf-8"))["results"]
        except (json.JSONDecodeError, KeyError) as error:
            errors.append(f"invalid nix-fast-build result: {error}")
    else:
        errors.append(f"nix-fast-build result not found: {result_path}")

    indexed_results = {
        (result["attr"], result["type"]): result
        for result in results
        if result.get("attr") in args.target and result.get("type") in {"EVAL", "BUILD"}
    }
    unexpected_targets = sorted(
        {
            str(result.get("attr", "<missing attr>"))
            for result in results
            if result.get("attr") not in args.target
        }
    )
    if unexpected_targets:
        errors.append(f"unexpected targets in result: {', '.join(unexpected_targets)}")

    drv_paths = {}
    for target in args.target:
        evaluation = indexed_results.get((target, "EVAL"))
        if not evaluation or not evaluation.get("success"):
            continue
        try:
            drv_paths[target] = run(
                "nix",
                "eval",
                "--raw",
                f"{check_installable(args.flake, args.system, target)}.drvPath",
            ).strip()
        except subprocess.CalledProcessError as error:
            errors.append(f"failed to resolve drvPath for {target}: {error}")

    builds_by_drv = {}
    for target in args.target:
        build = indexed_results.get((target, "BUILD"))
        drv_path = drv_paths.get(target)
        if build is not None and drv_path is not None:
            builds_by_drv.setdefault(drv_path, []).append(build)

    metrics = []
    for target in args.target:
        evaluation = indexed_results.get((target, "EVAL"))
        build = indexed_results.get((target, "BUILD"))
        drv_path = drv_paths.get(target)
        equivalent_builds = builds_by_drv.get(drv_path, []) if drv_path else []
        successful_build = next(
            (
                build_result
                for build_result in equivalent_builds
                if build_result.get("success")
            ),
            None,
        )
        build = successful_build or (
            equivalent_builds[0] if equivalent_builds else build
        )

        outputs = build.get("outputs") if build and build.get("success") else None
        store_path = (
            (outputs.get("out") or next(iter(outputs.values()))) if outputs else None
        )

        if evaluation is None:
            status = "missing evaluation"
        elif not evaluation["success"]:
            status = "evaluation failed"
        elif build is None:
            status = "missing build"
        elif not build["success"]:
            status = "build failed"
        else:
            status = "success"

        metrics.append(
            {
                "target": target,
                "status": status,
                "storePath": store_path,
                "closureNarSize": None,
                "closurePaths": None,
            }
        )

    path_metrics = {}
    for store_path in dict.fromkeys(
        metric["storePath"] for metric in metrics if metric["storePath"]
    ):
        try:
            path_info = json.loads(
                run(
                    "nix",
                    "path-info",
                    "--json",
                    "--recursive",
                    "--closure-size",
                    store_path,
                )
            )
            path_metrics[store_path] = {
                "closureNarSize": path_info[store_path]["closureSize"],
                "closurePaths": len(path_info),
            }
        except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as error:
            errors.append(f"failed to inspect {store_path}: {error}")

    for metric in metrics:
        if metric["storePath"] in path_metrics:
            metric.update(path_metrics[metric["storePath"]])

    print(f"## Demo build metrics — `{html.escape(args.system)}`")
    print()
    print("| Target | Result | Closure NAR size | Closure paths |")
    print("| --- | ---: | ---: | ---: |")
    for metric in metrics:
        if metric["status"] == "success":
            result = "✅"
        else:
            result = f"❌ {html.escape(metric['status'])}"
        print(
            f"| <code>{html.escape(metric['target'])}</code> | {result} | "
            f"{format_size(metric['closureNarSize'])} | "
            f"{metric['closurePaths'] if metric['closurePaths'] is not None else '—'} |"
        )

    print()
    print(
        "Closure NAR size is the serialized size of the complete runtime closure. "
        "Closure paths is the number of unique Nix store paths reachable from the output."
    )

    if errors:
        print()
        print("<details>")
        print("<summary>Metrics collection warnings</summary>")
        print()
        for error in errors:
            print(f"- {html.escape(error)}")
        print("</details>")
        raise SystemExit("incomplete demo build metrics")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--system", required=True)
    parser.add_argument("--flake", required=True)
    parser.add_argument("--result", required=True)
    parser.add_argument("--target", action="append", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    summarize(parse_args())
