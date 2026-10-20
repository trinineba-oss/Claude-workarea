"""Run the game's headless tests on any system (Windows, Mac, Linux): the same checks as
`make test`. A test fails if it exits non-zero, times out, or prints a script error.

    python projects/pixel-game/tools/run_tests.py            # every test
    python projects/pixel-game/tools/run_tests.py combat     # tests whose name contains "combat"

Godot is found on PATH (godot, godot4) or from the GODOT environment variable.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
ERRORS = ("SCRIPT ERROR", "Parse Error", "Compile Error")
TIMEOUT = 120


def find_godot() -> str:
    explicit = os.environ.get("GODOT")
    if explicit:
        return explicit
    for name in ("godot", "godot4", "Godot"):
        found = shutil.which(name)
        if found:
            return found
    sys.exit("Godot not found: put it on PATH or set GODOT to its path (see docs/00-local-setup.md)")


def main() -> int:
    godot = find_godot()
    only = sys.argv[1] if len(sys.argv) > 1 else ""
    print(f"importing {PROJECT.name} ...")
    subprocess.run(
        [godot, "--headless", "--path", str(PROJECT), "--import"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    tests = sorted(t for t in (PROJECT / "tests").glob("*_test.gd") if only in t.stem)
    failed = []
    for test in tests:
        try:
            run = subprocess.run(
                [godot, "--headless", "--path", str(PROJECT), "--script", f"res://tests/{test.name}"],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=TIMEOUT,
                check=False,
            )
            output = run.stdout + run.stderr
            ok = run.returncode == 0 and not any(e in output for e in ERRORS)
        except subprocess.TimeoutExpired:
            output, ok = f"timed out after {TIMEOUT} s", False
        print(f"{'PASS' if ok else 'FAIL'}  {test.name}")
        if not ok:
            failed.append(test.name)
            print(output)
    print(f"\n{len(tests) - len(failed)} of {len(tests)} tests passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
