"""Cross-platform headless Godot checks. No shell, no player save writes."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKS = {
    "aim": (["--fixed-fps", "60", "--quit-after", "1800", "tools/aim_check.tscn", "--", "--isolated-settings"], "AIM_OK"),
    "hunting": (["--fixed-fps", "60", "--quit-after", "1800", "tools/hunting_check.tscn", "--", "--isolated-settings"], "HUNTING_OK"),
    "field": (["--fixed-fps", "60", "--quit-after", "1800", "tools/field_check.tscn", "--", "--isolated-settings"], "FIELD_OK"),
    "revision": (["--fixed-fps", "60", "--quit-after", "1800", "tools/revision_check.tscn", "--", "--isolated-settings"], "REVISION_OK"),
    "presentation": (["--fixed-fps", "60", "--quit-after", "1800", "tools/presentation_check.tscn", "--", "--isolated-settings"], "PRESENTATION_OK"),
    "ranger": (["--fixed-fps", "60", "--quit-after", "1800", "tools/ranger_check.tscn", "--", "--isolated-settings"], "RANGER_CHECK_OK"),
    "visual_slice": (["--fixed-fps", "60", "--quit-after", "1800", "tools/visual_slice_check.tscn", "--", "--isolated-settings"], "VISUAL_SLICE_CHECK_OK"),
    "interior": (["--fixed-fps", "60", "--quit-after", "1800", "tools/interior_check.tscn", "--", "--isolated-settings"], "INTERIOR_OK"),
    "chapter": (["--fixed-fps", "60", "--quit-after", "1800", "tools/chapter_check.tscn", "--", "--isolated-settings"], "CHAPTER_OK"),
    "exploration": (["--fixed-fps", "60", "--quit-after", "1800", "tools/exploration_check.tscn", "--", "--isolated-settings"], "EXPLORATION_OK"),
    "day_cycle": (["--fixed-fps", "60", "--quit-after", "1800", "--", "--day-cycle-test"], "DAY_CYCLE_OK"),
    "snow_ui": (["--fixed-fps", "60", "--quit-after", "1800", "--", "--snow-ui-test"], "SNOW_UI_OK"),
    "rules": (["--script", "res://tests/expedition_test.gd"], "EXPEDITION_RESULT failures=0"),
    "integration": (["--fixed-fps", "60", "--quit-after", "1800", "--", "--integration"], "INTEGRATION_OK"),
    "polish": (["--fixed-fps", "60", "--quit-after", "1800", "--", "--polish-test"], "POLISH_OK"),
    "frontier": (["--fixed-fps", "60", "--quit-after", "1800", "--", "--frontier-test"], "FRONTIER_OK"),
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN"))
    parser.add_argument("--suite", choices=["all", *CHECKS], default="all")
    args = parser.parse_args()
    binary = args.godot or shutil.which("godot") or shutil.which("godot4")
    mac = Path("/Applications/Godot.app/Contents/MacOS/Godot")
    if not binary and mac.exists():
        binary = str(mac)
    if not binary:
        parser.error("Provide --godot, set GODOT_BIN, or put Godot on PATH.")
    output = ROOT / "artifacts"
    output.mkdir(exist_ok=True)
    # These test saves/settings are deliberately ignored by Git. A fresh
    # checkout must be able to run the suites without old local artifacts.
    for directory in ("interior", "chapter", "exploration", "field"):
        (output / directory).mkdir(exist_ok=True)
    tasks = [("import", (["--editor", "--import", "--quit"], None))]
    tasks += list(CHECKS.items()) if args.suite == "all" else [(args.suite, CHECKS[args.suite])]
    for name, (extra, marker) in tasks:
        command = [binary, "--headless", "--path", str(ROOT), *extra]
        try:
            result = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=180)
        except (OSError, subprocess.TimeoutExpired) as exc:
            print(f"FAIL {name}: {exc}")
            return 1
        log = result.stdout.decode("utf-8", errors="replace") + result.stderr.decode("utf-8", errors="replace")
        (output / f"checks-{name}.log").write_text(log, encoding="utf-8")
        bad = any(token in log for token in ["SCRIPT ERROR", "ERROR:", "Assertion failed", "leaked at exit"])
        if result.returncode or bad or (marker and marker not in log):
            print(f"FAIL {name}: inspect artifacts/checks-{name}.log")
            return 1
        print(f"PASS {name}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
