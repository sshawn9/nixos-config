#!/usr/bin/env python3

import argparse
import html
import json
import subprocess
from pathlib import Path


SYSTEMS = (
    "x86_64-linux",
    "aarch64-linux",
    "x86_64-darwin",
    "aarch64-darwin",
)


def run(*args: str) -> str:
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def collect(args: argparse.Namespace) -> None:
    result_path = Path(args.result)
    errors = []
    results = []
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

    metrics = []
    for target in args.target:
        evaluation = indexed_results.get((target, "EVAL"))
        build = indexed_results.get((target, "BUILD"))
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
                "evaluationDuration": evaluation["duration"] if evaluation else None,
                "buildDuration": build["duration"] if build else None,
                "closureNarSize": None,
                "closurePaths": None,
                "storePath": store_path,
                "metricsError": None,
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
            message = f"failed to inspect {store_path}: {error}"
            errors.append(message)
            path_metrics[store_path] = {"metricsError": message}

    for metric in metrics:
        if metric["storePath"]:
            metric.update(path_metrics[metric["storePath"]])

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "system": args.system,
                "targets": metrics,
                "errors": errors,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    if errors:
        raise SystemExit("; ".join(errors))


def format_duration(seconds: float | None, *, evaluation: bool = False) -> str:
    if seconds is None:
        return "—"
    if evaluation and seconds == 0:
        return "0 ms<sup>*</sup>"
    if seconds < 1:
        return f"{seconds * 1000:.0f} ms"
    if seconds < 60:
        return f"{seconds:.2f} s"
    minutes, remainder = divmod(seconds, 60)
    return f"{int(minutes)}m {remainder:.1f}s"


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


def render(args: argparse.Namespace) -> None:
    reports = {}
    render_errors = []
    for path in Path(args.input).rglob("metrics.json"):
        try:
            report = json.loads(path.read_text(encoding="utf-8"))
            system = report["system"]
            if system in reports:
                render_errors.append(f"duplicate report for {system}: {path}")
            reports[system] = report
        except (json.JSONDecodeError, KeyError) as error:
            render_errors.append(f"invalid metrics report {path}: {error}")

    print("## Demo build metrics")
    print()
    print(
        "| Platform | Target | Result | Evaluation duration | Build duration | "
        "Closure NAR size | Closure paths | Store path |"
    )
    print("| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |")

    for system_name in SYSTEMS:
        report = reports.get(system_name)
        system = html.escape(system_name)
        if report is None:
            render_errors.append(f"missing metrics report for {system_name}")
            print(
                f"| <code>{system}</code> | <em>report missing</em> | ❌ | — | — | — | — | — |"
            )
            continue

        for target in report["targets"]:
            result = (
                "✅"
                if target["status"] == "success"
                else f"❌ {html.escape(target['status'])}"
            )
            name = html.escape(target["target"])
            store_path = target["storePath"]
            formatted_path = (
                f"<code>{html.escape(store_path)}</code>" if store_path else "—"
            )
            print(
                f"| <code>{system}</code> | <code>{name}</code> | {result} | "
                f"{format_duration(target['evaluationDuration'], evaluation=True)} | "
                f"{format_duration(target['buildDuration'])} | "
                f"{format_size(target.get('closureNarSize'))} | "
                f"{target['closurePaths'] if target['closurePaths'] is not None else '—'} | "
                f"{formatted_path} |"
            )

        render_errors.extend(
            f"{system_name}: {error}" for error in report.get("errors", [])
        )

    print()
    print(
        "Closure NAR size is the serialized size of the complete runtime closure. "
        "Closure paths is the number of unique Nix store paths reachable from the output."
    )
    print()
    print(
        "<sup>*</sup> `0 ms` is the value reported by nix-fast-build 1.6.0; "
        "no separate warm-cache evaluation benchmark was run."
    )

    if render_errors:
        print()
        print("<details>")
        print("<summary>Metrics collection warnings</summary>")
        print()
        for error in render_errors:
            print(f"- {html.escape(error)}")
        print("</details>")
        raise SystemExit("incomplete demo build metrics")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    collect_parser = subparsers.add_parser("collect")
    collect_parser.add_argument("--system", required=True)
    collect_parser.add_argument("--result", required=True)
    collect_parser.add_argument("--output", required=True)
    collect_parser.add_argument("--target", action="append", required=True)

    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("--input", required=True)

    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.command == "collect":
        collect(args)
    else:
        render(args)


if __name__ == "__main__":
    main()
