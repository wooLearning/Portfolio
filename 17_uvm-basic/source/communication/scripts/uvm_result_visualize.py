#!/usr/bin/env python3
"""
Parse Vivado/XSim UVM logs and coverage reports, then generate CSV/SVG summaries.

If pandas and matplotlib are installed, PNG charts are generated as well.
"""

from __future__ import annotations

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path


BENCH_ORDER = [
    "UART RX",
    "UART TX",
    "SPI MASTER",
    "SPI SLAVE",
    "I2C MASTER",
    "I2C SLAVE",
]

SCENARIO_ORDER = [
    "smoke",
    "directed",
    "error",
    "busy",
    "mode",
    "abort",
    "reset",
    "timeout",
    "jitter",
    "corner",
    "byte_sweep",
    "full_random",
    "all",
    "vcd",
]


@dataclass
class RunResult:
    bench: str
    scenario: str
    path: Path
    scoreboard_pass: int | None
    scoreboard_fail: int | None
    uvm_error: int | None
    uvm_fatal: int | None
    raw_error_count: int
    status: str


@dataclass
class CoverageResult:
    bench: str
    score: float
    path: Path


@dataclass
class CoverpointResult:
    bench: str
    coverpoint: str
    expected: int
    uncovered: int
    covered: int
    percent: float
    path: Path


def bench_from_path(path: Path) -> str | None:
    parts = [part.upper() for part in path.parts]
    if "TB" not in parts:
        return None
    try:
        tb_idx = parts.index("TB")
        proto = parts[tb_idx + 1]
        role = parts[tb_idx + 2]
    except IndexError:
        return None
    if proto in {"UART", "SPI", "I2C"}:
        return f"{proto} {role}"
    return None


def scenario_from_log(path: Path) -> str:
    match = re.match(r"xsim_(.+?)(?:_\d+\.backup)?\.log$", path.name)
    return match.group(1) if match else "unknown"


def parse_log(path: Path) -> RunResult | None:
    bench = bench_from_path(path)
    if bench is None:
        return None

    text = path.read_text(errors="ignore")
    scoreboard_matches = re.findall(r"Scoreboard pass=(\d+)\s+fail=(\d+)", text)
    error_matches = re.findall(r"UVM_ERROR\s*:\s*(\d+)", text)
    fatal_matches = re.findall(r"UVM_FATAL\s*:\s*(\d+)", text)

    scoreboard_pass = int(scoreboard_matches[-1][0]) if scoreboard_matches else None
    scoreboard_fail = int(scoreboard_matches[-1][1]) if scoreboard_matches else None
    uvm_error = int(error_matches[-1]) if error_matches else None
    uvm_fatal = int(fatal_matches[-1]) if fatal_matches else None
    raw_error_count = sum(
        1
        for line in text.splitlines()
        if line.startswith("Error:") or "FATAL_ERROR" in line
    )

    has_fail = (
        (scoreboard_fail or 0) > 0
        or (uvm_error or 0) > 0
        or (uvm_fatal or 0) > 0
        or raw_error_count > 0
    )
    has_summary = scoreboard_pass is not None or uvm_error is not None or uvm_fatal is not None
    status = "PASS" if has_summary and not has_fail else "FAIL" if has_summary else "UNKNOWN"

    return RunResult(
        bench=bench,
        scenario=scenario_from_log(path),
        path=path,
        scoreboard_pass=scoreboard_pass,
        scoreboard_fail=scoreboard_fail,
        uvm_error=uvm_error,
        uvm_fatal=uvm_fatal,
        raw_error_count=raw_error_count,
        status=status,
    )


def parse_coverage(path: Path) -> CoverageResult | None:
    bench = bench_from_path(path)
    if bench is None:
        return None

    text = path.read_text(errors="ignore")
    matches = re.findall(r"Coverage Score\s*[:,]+\s*([0-9.]+)", text)
    if not matches:
        return None
    return CoverageResult(bench=bench, score=float(matches[-1]), path=path)


def parse_coverpoints(path: Path) -> list[CoverpointResult]:
    bench = bench_from_path(path)
    if bench is None:
        return []

    results: list[CoverpointResult] = []
    for line in path.read_text(errors="ignore").splitlines():
        if not re.match(r"\s*cp_[A-Za-z0-9_]+\s*,", line):
            continue

        parts = [part.strip() for part in line.split(",")]
        if len(parts) < 6:
            continue

        try:
            results.append(
                CoverpointResult(
                    bench=bench,
                    coverpoint=parts[0],
                    expected=int(parts[2]),
                    uncovered=int(parts[3]),
                    covered=int(parts[4]),
                    percent=float(parts[5]),
                    path=path,
                )
            )
        except ValueError:
            continue

    return results


def sort_key(result: RunResult) -> tuple[int, int, str]:
    bench_idx = BENCH_ORDER.index(result.bench) if result.bench in BENCH_ORDER else len(BENCH_ORDER)
    scenario_idx = SCENARIO_ORDER.index(result.scenario) if result.scenario in SCENARIO_ORDER else len(SCENARIO_ORDER)
    return bench_idx, scenario_idx, str(result.path)


def write_run_csv(results: list[RunResult], out_path: Path) -> None:
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "bench",
                "scenario",
                "status",
                "scoreboard_pass",
                "scoreboard_fail",
                "uvm_error",
                "uvm_fatal",
                "raw_error_count",
                "log",
            ],
        )
        writer.writeheader()
        for result in sorted(results, key=sort_key):
            writer.writerow(
                {
                    "bench": result.bench,
                    "scenario": result.scenario,
                    "status": result.status,
                    "scoreboard_pass": result.scoreboard_pass,
                    "scoreboard_fail": result.scoreboard_fail,
                    "uvm_error": result.uvm_error,
                    "uvm_fatal": result.uvm_fatal,
                    "raw_error_count": result.raw_error_count,
                    "log": result.path.as_posix(),
                }
            )


def write_coverage_csv(results: list[CoverageResult], out_path: Path) -> None:
    by_bench = {result.bench: result for result in results}
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["bench", "coverage_score", "report"])
        writer.writeheader()
        for bench in BENCH_ORDER:
            result = by_bench.get(bench)
            writer.writerow(
                {
                    "bench": bench,
                    "coverage_score": "" if result is None else result.score,
                    "report": "" if result is None else result.path.as_posix(),
                }
            )


def write_coverpoint_csv(results: list[CoverpointResult], out_path: Path) -> None:
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "bench",
                "coverpoint",
                "expected",
                "uncovered",
                "covered",
                "percent",
                "report",
            ],
        )
        writer.writeheader()
        for result in sorted(
            results,
            key=lambda item: (
                BENCH_ORDER.index(item.bench) if item.bench in BENCH_ORDER else len(BENCH_ORDER),
                item.coverpoint,
            ),
        ):
            writer.writerow(
                {
                    "bench": result.bench,
                    "coverpoint": result.coverpoint,
                    "expected": result.expected,
                    "uncovered": result.uncovered,
                    "covered": result.covered,
                    "percent": result.percent,
                    "report": result.path.as_posix(),
                }
            )


def all_run_by_bench(results: list[RunResult]) -> dict[str, RunResult]:
    return {result.bench: result for result in results if result.scenario == "all"}


def coverage_by_bench(results: list[CoverageResult]) -> dict[str, float]:
    return {result.bench: result.score for result in results}


def write_all_csv(run_results: list[RunResult], cov_results: list[CoverageResult], out_path: Path) -> None:
    runs = all_run_by_bench(run_results)
    coverage = coverage_by_bench(cov_results)

    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "bench",
                "all_status",
                "scoreboard_pass",
                "scoreboard_fail",
                "uvm_error",
                "uvm_fatal",
                "raw_error_count",
                "coverage_score",
                "all_log",
            ],
        )
        writer.writeheader()
        for bench in BENCH_ORDER:
            result = runs.get(bench)
            writer.writerow(
                {
                    "bench": bench,
                    "all_status": "" if result is None else result.status,
                    "scoreboard_pass": "" if result is None else result.scoreboard_pass,
                    "scoreboard_fail": "" if result is None else result.scoreboard_fail,
                    "uvm_error": "" if result is None else result.uvm_error,
                    "uvm_fatal": "" if result is None else result.uvm_fatal,
                    "raw_error_count": "" if result is None else result.raw_error_count,
                    "coverage_score": coverage.get(bench, ""),
                    "all_log": "" if result is None else result.path.as_posix(),
                }
            )


def write_sequence_count_csv(run_results: list[RunResult], out_path: Path) -> None:
    current = {(result.bench, result.scenario): result for result in run_results}

    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["bench", *SCENARIO_ORDER])
        for bench in BENCH_ORDER:
            row = [bench]
            for scenario in SCENARIO_ORDER:
                result = current.get((bench, scenario))
                row.append("" if result is None else result.scoreboard_pass)
            writer.writerow(row)


def status_color(status: str) -> str:
    return {"PASS": "#2e7d32", "FAIL": "#c62828", "UNKNOWN": "#9e9e9e", "MISSING": "#eeeeee"}[status]


def svg_header(width: int, height: int, title: str, subtitle: str) -> list[str]:
    return [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        f'<text x="28" y="36" font-family="Arial" font-size="24" font-weight="700" fill="#1f2933">{title}</text>',
        f'<text x="28" y="60" font-family="Arial" font-size="13" fill="#52616b">{subtitle}</text>',
    ]


def write_status_matrix_svg(run_results: list[RunResult], out_path: Path) -> None:
    current = {(result.bench, result.scenario): result for result in run_results}
    width = 1180
    height = 460
    left = 140
    top = 96
    cell_w = 86
    cell_h = 42

    lines = svg_header(
        width,
        height,
        "UVM Scenario Pass/Fail Matrix",
        "Green means scoreboard fail=0, UVM_ERROR=0, UVM_FATAL=0, and raw simulator Error count=0.",
    )
    lines.append('<rect x="20" y="76" width="1140" height="320" rx="8" fill="#f8fafc" stroke="#d9e2ec"/>')

    for col, scenario in enumerate(SCENARIO_ORDER):
        x = left + col * cell_w + cell_w / 2
        lines.append(
            f'<text x="{x}" y="{top - 16}" text-anchor="middle" font-family="Arial" '
            f'font-size="12" font-weight="700" fill="#334e68">{scenario}</text>'
        )

    for row, bench in enumerate(BENCH_ORDER):
        y = top + row * cell_h
        lines.append(
            f'<text x="34" y="{y + 27}" font-family="Arial" font-size="14" '
            f'font-weight="700" fill="#1f2933">{bench}</text>'
        )
        for col, scenario in enumerate(SCENARIO_ORDER):
            x = left + col * cell_w
            result = current.get((bench, scenario))
            status = result.status if result else "MISSING"
            fill = status_color(status)
            label = "PASS" if status == "PASS" else "FAIL" if status == "FAIL" else "-"
            text_color = "#ffffff" if status in {"PASS", "FAIL"} else "#6b7280"
            lines.append(f'<rect x="{x + 5}" y="{y + 6}" width="{cell_w - 10}" height="{cell_h - 12}" rx="5" fill="{fill}"/>')
            lines.append(
                f'<text x="{x + cell_w / 2}" y="{y + 26}" text-anchor="middle" '
                f'font-family="Arial" font-size="11" font-weight="700" fill="{text_color}">{label}</text>'
            )

    legend_y = 428
    for i, (label, color) in enumerate([("PASS", "#2e7d32"), ("FAIL", "#c62828"), ("not run as standalone", "#eeeeee")]):
        x = 32 + i * 180
        lines.append(f'<rect x="{x}" y="{legend_y - 14}" width="18" height="18" rx="4" fill="{color}" stroke="#cbd5e1"/>')
        lines.append(f'<text x="{x + 26}" y="{legend_y}" font-family="Arial" font-size="13" fill="#334e68">{label}</text>')

    lines.append("</svg>")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_coverage_bars_svg(cov_results: list[CoverageResult], out_path: Path) -> None:
    coverage = coverage_by_bench(cov_results)
    width = 900
    height = 470
    left = 150
    top = 94
    bar_h = 36
    gap = 20
    max_w = 610

    lines = svg_header(
        width,
        height,
        "Functional Coverage by UVM Bench",
        "XCRG functional coverage report, regenerated after fresh all-sequence simulations.",
    )
    for idx, bench in enumerate(BENCH_ORDER):
        score = coverage.get(bench, 0.0)
        y = top + idx * (bar_h + gap)
        bar_w = max_w * score / 100.0
        fill = "#0f766e" if score >= 100.0 else "#2e7d32" if score >= 90 else "#ef6c00" if score >= 70 else "#c62828"
        lines.append(f'<text x="28" y="{y + 24}" font-family="Arial" font-size="15" font-weight="700" fill="#1f2933">{bench}</text>')
        lines.append(f'<rect x="{left}" y="{y}" width="{max_w}" height="{bar_h}" rx="5" fill="#e5e7eb"/>')
        lines.append(f'<rect x="{left}" y="{y}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{fill}"/>')
        lines.append(f'<text x="{left + max_w + 18}" y="{y + 24}" font-family="Arial" font-size="15" font-weight="700" fill="#1f2933">{score:.1f}%</text>')

    axis_y = top + len(BENCH_ORDER) * (bar_h + gap) + 10
    for pct in range(0, 101, 20):
        x = left + max_w * pct / 100.0
        lines.append(f'<line x1="{x:.1f}" y1="88" x2="{x:.1f}" y2="{axis_y}" stroke="#edf2f7"/>')
        lines.append(f'<text x="{x:.1f}" y="{axis_y + 22}" text-anchor="middle" font-family="Arial" font-size="12" fill="#52616b">{pct}%</text>')

    lines.append("</svg>")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_scoreboard_bars_svg(run_results: list[RunResult], out_path: Path) -> None:
    runs = all_run_by_bench(run_results)
    max_pass = max((result.scoreboard_pass or 0) for result in runs.values()) if runs else 1
    width = 940
    height = 500
    left = 150
    top = 96
    bar_h = 34
    gap = 22
    max_w = 620

    lines = svg_header(
        width,
        height,
        "All-Sequence Scoreboard Results",
        "Horizontal bars show checked transaction count. Red fail overlay remains zero for all six benches.",
    )
    for idx, bench in enumerate(BENCH_ORDER):
        result = runs.get(bench)
        passed = 0 if result is None else (result.scoreboard_pass or 0)
        failed = 0 if result is None else (result.scoreboard_fail or 0)
        y = top + idx * (bar_h + gap)
        pass_w = max_w * passed / max_pass
        fail_w = max_w * failed / max_pass
        lines.append(f'<text x="28" y="{y + 23}" font-family="Arial" font-size="15" font-weight="700" fill="#1f2933">{bench}</text>')
        lines.append(f'<rect x="{left}" y="{y}" width="{max_w}" height="{bar_h}" rx="5" fill="#e5e7eb"/>')
        lines.append(f'<rect x="{left}" y="{y}" width="{pass_w:.1f}" height="{bar_h}" rx="5" fill="#2563eb"/>')
        if failed:
            lines.append(f'<rect x="{left + pass_w:.1f}" y="{y}" width="{fail_w:.1f}" height="{bar_h}" rx="5" fill="#c62828"/>')
        lines.append(
            f'<text x="{left + max_w + 18}" y="{y + 23}" font-family="Arial" '
            f'font-size="14" font-weight="700" fill="#1f2933">pass {passed} / fail {failed}</text>'
        )

    legend_y = 460
    lines.append(f'<rect x="28" y="{legend_y - 15}" width="18" height="18" rx="4" fill="#2563eb"/>')
    lines.append(f'<text x="54" y="{legend_y}" font-family="Arial" font-size="13" fill="#334e68">scoreboard pass count</text>')
    lines.append(f'<rect x="230" y="{legend_y - 15}" width="18" height="18" rx="4" fill="#c62828"/>')
    lines.append(f'<text x="256" y="{legend_y}" font-family="Arial" font-size="13" fill="#334e68">scoreboard fail count</text>')
    lines.append("</svg>")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def full_random_by_bench(results: list[RunResult]) -> dict[str, RunResult]:
    return {result.bench: result for result in results if result.scenario == "full_random"}


def write_random_bars_svg(run_results: list[RunResult], out_path: Path) -> None:
    runs = full_random_by_bench(run_results)
    max_pass = max((result.scoreboard_pass or 0) for result in runs.values()) if runs else 1
    width = 940
    height = 500
    left = 150
    top = 96
    bar_h = 34
    gap = 22
    max_w = 620

    lines = svg_header(
        width,
        height,
        "Full-Random Scoreboard Results",
        "Each bench is configured for at least 512 legal randomized transactions after directed corner coverage.",
    )
    for idx, bench in enumerate(BENCH_ORDER):
        result = runs.get(bench)
        passed = 0 if result is None else (result.scoreboard_pass or 0)
        failed = 0 if result is None else (result.scoreboard_fail or 0)
        raw = 0 if result is None else result.raw_error_count
        y = top + idx * (bar_h + gap)
        pass_w = max_w * passed / max_pass
        fill = "#0f766e" if passed >= 512 and failed == 0 and raw == 0 else "#ef6c00"
        lines.append(f'<text x="28" y="{y + 23}" font-family="Arial" font-size="15" font-weight="700" fill="#1f2933">{bench}</text>')
        lines.append(f'<rect x="{left}" y="{y}" width="{max_w}" height="{bar_h}" rx="5" fill="#e5e7eb"/>')
        lines.append(f'<rect x="{left}" y="{y}" width="{pass_w:.1f}" height="{bar_h}" rx="5" fill="{fill}"/>')
        lines.append(
            f'<text x="{left + max_w + 18}" y="{y + 23}" font-family="Arial" '
            f'font-size="14" font-weight="700" fill="#1f2933">pass {passed} / fail {failed} / raw {raw}</text>'
        )

    legend_y = 460
    lines.append(f'<rect x="28" y="{legend_y - 15}" width="18" height="18" rx="4" fill="#0f766e"/>')
    lines.append(f'<text x="54" y="{legend_y}" font-family="Arial" font-size="13" fill="#334e68">512+ pass, no fail, no raw simulator error</text>')
    lines.append("</svg>")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_svg_dashboard(run_results: list[RunResult], cov_results: list[CoverageResult], out_path: Path) -> None:
    current = {(result.bench, result.scenario): result for result in run_results}
    cov = {result.bench: result.score for result in cov_results}

    cell_w = 76
    cell_h = 32
    left_w = 118
    top_h = 72
    cov_w = 260
    width = left_w + cell_w * len(SCENARIO_ORDER) + cov_w + 40
    height = top_h + cell_h * len(BENCH_ORDER) + 64

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        '<text x="20" y="30" font-family="Arial" font-size="22" font-weight="700">UVM XSim Verification Dashboard</text>',
        '<text x="20" y="52" font-family="Arial" font-size="12" fill="#555">Generated from current xsim_*.log and XCRG coverage reports</text>',
    ]

    for idx, scenario in enumerate(SCENARIO_ORDER):
        x = left_w + idx * cell_w
        lines.append(
            f'<text x="{x + cell_w / 2}" y="{top_h - 12}" text-anchor="middle" '
            f'font-family="Arial" font-size="11" fill="#333">{scenario}</text>'
        )

    cov_x = left_w + cell_w * len(SCENARIO_ORDER) + 24
    lines.append(f'<text x="{cov_x}" y="{top_h - 12}" font-family="Arial" font-size="11" fill="#333">coverage</text>')

    for row, bench in enumerate(BENCH_ORDER):
        y = top_h + row * cell_h
        lines.append(f'<text x="20" y="{y + 21}" font-family="Arial" font-size="13" font-weight="700" fill="#222">{bench}</text>')
        for col, scenario in enumerate(SCENARIO_ORDER):
            x = left_w + col * cell_w
            result = current.get((bench, scenario))
            status = result.status if result else "MISSING"
            label = status[0] if result else "-"
            lines.append(f'<rect x="{x + 4}" y="{y + 4}" width="{cell_w - 8}" height="{cell_h - 8}" rx="4" fill="{status_color(status)}"/>')
            lines.append(
                f'<text x="{x + cell_w / 2}" y="{y + 23}" text-anchor="middle" '
                f'font-family="Arial" font-size="12" font-weight="700" fill="{"#fff" if status != "MISSING" else "#777"}">{label}</text>'
            )
        score = cov.get(bench)
        bar_y = y + 9
        lines.append(f'<rect x="{cov_x}" y="{bar_y}" width="180" height="14" fill="#eeeeee"/>')
        if score is not None:
            bar_w = max(0, min(180, 180 * score / 100.0))
            fill = "#2e7d32" if score >= 90 else "#ef6c00" if score >= 70 else "#c62828"
            lines.append(f'<rect x="{cov_x}" y="{bar_y}" width="{bar_w:.1f}" height="14" fill="{fill}"/>')
            lines.append(f'<text x="{cov_x + 190}" y="{bar_y + 12}" font-family="Arial" font-size="12" fill="#222">{score:.1f}%</text>')
        else:
            lines.append(f'<text x="{cov_x + 190}" y="{bar_y + 12}" font-family="Arial" font-size="12" fill="#777">N/A</text>')

    legend_y = height - 28
    legend = [("PASS", "#2e7d32"), ("FAIL", "#c62828"), ("UNKNOWN", "#9e9e9e"), ("MISSING", "#eeeeee")]
    x = 20
    for label, color in legend:
        lines.append(f'<rect x="{x}" y="{legend_y - 12}" width="16" height="16" rx="3" fill="{color}" stroke="#ccc"/>')
        lines.append(f'<text x="{x + 22}" y="{legend_y + 1}" font-family="Arial" font-size="12" fill="#333">{label}</text>')
        x += 100

    lines.append("</svg>")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def try_write_matplotlib_png(
    run_results: list[RunResult],
    cov_results: list[CoverageResult],
    coverpoint_results: list[CoverpointResult],
    out_dir: Path,
) -> list[Path]:
    try:
        import matplotlib.colors as mcolors
        import matplotlib.pyplot as plt
        import numpy as np
        import pandas as pd
    except ImportError:
        return []

    run_df = pd.DataFrame([result.__dict__ for result in run_results])
    cov_df = pd.DataFrame([result.__dict__ for result in cov_results])
    written: list[Path] = []

    plt.style.use("seaborn-v0_8-whitegrid")
    plt.rcParams.update(
        {
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "axes.edgecolor": "#cbd5e1",
            "axes.labelcolor": "#1f2933",
            "axes.titleweight": "bold",
            "font.size": 10,
            "savefig.dpi": 180,
        }
    )

    current = {(result.bench, result.scenario): result for result in run_results}

    def save(fig, name: str) -> None:
        path = out_dir / name
        fig.tight_layout()
        fig.savefig(path, bbox_inches="tight")
        plt.close(fig)
        written.append(path)

    def build_status_matrix() -> list[list[int]]:
        status_map = {"MISSING": 0, "UNKNOWN": 1, "FAIL": 2, "PASS": 3}
        matrix = []
        for bench in BENCH_ORDER:
            row = []
            for scenario in SCENARIO_ORDER:
                result = current.get((bench, scenario))
                row.append(status_map[result.status if result else "MISSING"])
            matrix.append(row)
        return matrix

    def annotate_status(ax) -> None:
        for y, bench in enumerate(BENCH_ORDER):
            for x, scenario in enumerate(SCENARIO_ORDER):
                result = current.get((bench, scenario))
                label = "P" if result and result.status == "PASS" else "F" if result and result.status == "FAIL" else "-"
                color = "white" if label in {"P", "F"} else "#64748b"
                ax.text(x, y, label, ha="center", va="center", color=color, fontweight="bold", fontsize=9)

    status_cmap = mcolors.ListedColormap(["#e5e7eb", "#9ca3af", "#dc2626", "#16a34a"])
    status_norm = mcolors.BoundaryNorm([-0.5, 0.5, 1.5, 2.5, 3.5], status_cmap.N)
    matrix = build_status_matrix()

    fig, (ax_status, ax_cov) = plt.subplots(1, 2, figsize=(15, 5), gridspec_kw={"width_ratios": [2.6, 1]})
    ax_status.imshow(matrix, aspect="auto", cmap=status_cmap, norm=status_norm)
    ax_status.set_xticks(range(len(SCENARIO_ORDER)), SCENARIO_ORDER, rotation=45, ha="right")
    ax_status.set_yticks(range(len(BENCH_ORDER)), BENCH_ORDER)
    ax_status.set_title("Scenario Status")
    ax_status.grid(False)
    annotate_status(ax_status)

    cov_by_bench = {row["bench"]: row["score"] for _, row in cov_df.iterrows()} if not cov_df.empty else {}
    cov_values = [cov_by_bench.get(bench, 0.0) for bench in BENCH_ORDER]
    ax_cov.barh(
        BENCH_ORDER,
        cov_values,
        color=[
            "#0f766e" if value >= 100 else "#16a34a" if value >= 90 else "#f59e0b" if value >= 70 else "#dc2626"
            for value in cov_values
        ],
    )
    ax_cov.set_xlim(0, 100)
    ax_cov.set_title("Functional Coverage")
    ax_cov.set_xlabel("%")
    ax_cov.invert_yaxis()
    for idx, value in enumerate(cov_values):
        ax_cov.text(min(value + 1, 98), idx, f"{value:.1f}%", va="center", fontweight="bold")
    save(fig, "uvm_dashboard.png")

    fig, ax = plt.subplots(figsize=(14, 5))
    ax.imshow(matrix, aspect="auto", cmap=status_cmap, norm=status_norm)
    ax.set_xticks(range(len(SCENARIO_ORDER)), SCENARIO_ORDER, rotation=45, ha="right")
    ax.set_yticks(range(len(BENCH_ORDER)), BENCH_ORDER)
    ax.set_title("UVM Scenario Pass/Fail Matrix")
    ax.grid(False)
    annotate_status(ax)
    save(fig, "uvm_status_matrix.png")

    fig, ax = plt.subplots(figsize=(9, 4.8))
    ax.barh(BENCH_ORDER, cov_values, color="#0f766e")
    ax.set_xlim(0, 105)
    ax.set_title("Functional Coverage by Bench")
    ax.set_xlabel("Coverage (%)")
    ax.invert_yaxis()
    for idx, value in enumerate(cov_values):
        ax.text(value + 1, idx, f"{value:.1f}%", va="center", fontweight="bold")
    save(fig, "uvm_coverage_bars.png")

    def plot_scoreboard(scenario: str, title: str, path_name: str) -> None:
        results = [current.get((bench, scenario)) for bench in BENCH_ORDER]
        passes = [0 if result is None else (result.scoreboard_pass or 0) for result in results]
        fails = [0 if result is None else (result.scoreboard_fail or 0) for result in results]
        raw_errors = [0 if result is None else result.raw_error_count for result in results]

        fig, ax = plt.subplots(figsize=(10, 5))
        y = range(len(BENCH_ORDER))
        ax.barh(y, passes, color="#2563eb", label="scoreboard pass")
        ax.barh(y, fails, left=passes, color="#dc2626", label="scoreboard fail")
        ax.set_yticks(list(y), BENCH_ORDER)
        ax.invert_yaxis()
        ax.set_title(title)
        ax.set_xlabel("Transactions")
        ax.legend(loc="lower right")
        max_value = max(passes + [1])
        ax.set_xlim(0, max_value * 1.22)
        for idx, (passed, failed, raw) in enumerate(zip(passes, fails, raw_errors)):
            ax.text(
                passed + max_value * 0.02,
                idx,
                f"pass {passed} / fail {failed} / raw {raw}",
                va="center",
                fontweight="bold",
                color="#1f2933",
            )
        save(fig, path_name)

    plot_scoreboard("all", "All-Sequence Scoreboard Results", "uvm_scoreboard_bars.png")
    plot_scoreboard("byte_sweep", "Byte-Sweep 0x00-0xFF Results", "uvm_byte_sweep_bars.png")
    plot_scoreboard("full_random", "Full-Random Scoreboard Results", "uvm_full_random_bars.png")

    count_matrix = []
    for bench in BENCH_ORDER:
        row = []
        for scenario in SCENARIO_ORDER:
            result = current.get((bench, scenario))
            row.append(np.nan if result is None else float(result.scoreboard_pass or 0))
        count_matrix.append(row)

    fig, ax = plt.subplots(figsize=(14, 5.2))
    cmap = plt.get_cmap("YlGnBu").copy()
    cmap.set_bad("#e5e7eb")
    valid_values = [value for row in count_matrix for value in row if not np.isnan(value)]
    vmax = max(valid_values) if valid_values else 1
    image = ax.imshow(count_matrix, aspect="auto", cmap=cmap, vmin=0, vmax=vmax)
    ax.set_xticks(range(len(SCENARIO_ORDER)), SCENARIO_ORDER, rotation=45, ha="right")
    ax.set_yticks(range(len(BENCH_ORDER)), BENCH_ORDER)
    ax.set_title("Sequence Execution Count by Bench")
    ax.grid(False)
    for y, bench in enumerate(BENCH_ORDER):
        for x, scenario in enumerate(SCENARIO_ORDER):
            result = current.get((bench, scenario))
            if result is None:
                label = "-"
                color = "#64748b"
            else:
                label = str(result.scoreboard_pass or 0)
                color = "white" if (result.scoreboard_pass or 0) > vmax * 0.55 else "#1f2933"
            ax.text(x, y, label, ha="center", va="center", color=color, fontweight="bold", fontsize=8)
    cbar = fig.colorbar(image, ax=ax, fraction=0.025, pad=0.02)
    cbar.set_label("Scoreboard pass count")
    save(fig, "uvm_sequence_counts.png")

    if coverpoint_results:
        ordered_coverpoints = sorted(
            coverpoint_results,
            key=lambda item: (
                BENCH_ORDER.index(item.bench) if item.bench in BENCH_ORDER else len(BENCH_ORDER),
                item.coverpoint,
            ),
        )
        labels = [f"{item.bench} / {item.coverpoint}" for item in ordered_coverpoints]
        values = [item.percent for item in ordered_coverpoints]

        fig_h = max(5.0, 0.33 * len(labels))
        fig, ax = plt.subplots(figsize=(11, fig_h))
        colors = ["#0f766e" if value >= 100 else "#16a34a" if value >= 90 else "#f59e0b" if value >= 70 else "#dc2626" for value in values]
        y = range(len(labels))
        ax.barh(y, values, color=colors)
        ax.set_yticks(list(y), labels)
        ax.invert_yaxis()
        ax.set_xlim(0, 108)
        ax.set_title("Coverpoint Coverage Detail")
        ax.set_xlabel("Coverage (%)")
        for idx, item in enumerate(ordered_coverpoints):
            ax.text(
                item.percent + 1,
                idx,
                f"{item.percent:.0f}% ({item.covered}/{item.expected}, uncv {item.uncovered})",
                va="center",
                fontweight="bold",
                fontsize=9,
            )
        save(fig, "uvm_coverpoint_coverage.png")
    return written


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Project root directory")
    parser.add_argument("--out", default="reports/uvm_results", help="Output directory")
    parser.add_argument("--include-backups", action="store_true", help="Include xsim_*_NN.backup.log files")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = (root / args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    log_paths = sorted(root.glob("TB/*/*/xsim_*.log"))
    if not args.include_backups:
        log_paths = [path for path in log_paths if ".backup.log" not in path.name]
    run_results = [result for path in log_paths if (result := parse_log(path)) is not None]

    cov_paths = sorted(root.glob("TB/*/*/xsim_coverage_report/functionalCoverageReport/xcrg_func_cov_report.txt"))
    cov_results = [result for path in cov_paths if (result := parse_coverage(path)) is not None]
    coverpoint_results = [result for path in cov_paths for result in parse_coverpoints(path)]

    write_run_csv(run_results, out_dir / "uvm_run_summary.csv")
    write_coverage_csv(cov_results, out_dir / "uvm_coverage_summary.csv")
    write_coverpoint_csv(coverpoint_results, out_dir / "uvm_coverpoint_coverage.csv")
    write_all_csv(run_results, cov_results, out_dir / "uvm_all_summary.csv")
    write_sequence_count_csv(run_results, out_dir / "uvm_sequence_counts.csv")
    write_svg_dashboard(run_results, cov_results, out_dir / "uvm_dashboard.svg")
    write_status_matrix_svg(run_results, out_dir / "uvm_status_matrix.svg")
    write_coverage_bars_svg(cov_results, out_dir / "uvm_coverage_bars.svg")
    write_scoreboard_bars_svg(run_results, out_dir / "uvm_scoreboard_bars.svg")
    write_random_bars_svg(run_results, out_dir / "uvm_full_random_bars.svg")
    png_paths = try_write_matplotlib_png(run_results, cov_results, coverpoint_results, out_dir)

    print(f"Parsed logs: {len(run_results)}")
    print(f"Parsed coverage reports: {len(cov_results)}")
    print(f"Wrote: {out_dir / 'uvm_run_summary.csv'}")
    print(f"Wrote: {out_dir / 'uvm_coverage_summary.csv'}")
    print(f"Wrote: {out_dir / 'uvm_coverpoint_coverage.csv'}")
    print(f"Wrote: {out_dir / 'uvm_all_summary.csv'}")
    print(f"Wrote: {out_dir / 'uvm_sequence_counts.csv'}")
    print(f"Wrote: {out_dir / 'uvm_dashboard.svg'}")
    print(f"Wrote: {out_dir / 'uvm_status_matrix.svg'}")
    print(f"Wrote: {out_dir / 'uvm_coverage_bars.svg'}")
    print(f"Wrote: {out_dir / 'uvm_scoreboard_bars.svg'}")
    print(f"Wrote: {out_dir / 'uvm_full_random_bars.svg'}")
    if png_paths:
        for path in png_paths:
            print(f"Wrote: {path}")
    else:
        print("Skipped PNG: install pandas and matplotlib to enable PNG output")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
