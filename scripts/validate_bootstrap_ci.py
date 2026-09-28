#!/usr/bin/env python3
"""Run bootstrap validation with CI event/ref gating."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def require_active(event_name: str, ref: str) -> bool:
    return event_name == "push" and ref == "refs/heads/main"


def command(event_name: str, ref: str, path: str) -> list[str]:
    script = Path(__file__).with_name("validate_bootstrap.py")
    cmd = [sys.executable, str(script), path]
    if require_active(event_name, ref):
        cmd.append("--require-active")
    return cmd


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--event-name", required=True)
    parser.add_argument("--ref", required=True)
    parser.add_argument("--path", default="config/bootstrap.json")
    args = parser.parse_args(argv)
    return subprocess.run(command(args.event_name, args.ref, args.path), check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
