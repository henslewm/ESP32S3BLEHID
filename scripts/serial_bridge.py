"""Long-running serial bridge for agent-driven firmware sessions.

Holds the port open (Windows allows only one opener), appends every received
line to a timestamped log, and sends any text appended to an inbox file.

  python scripts/serial_bridge.py --port COM10 --log build/serial/session.log
  # send a command from another shell:
  #   Add-Content build/serial/inbox.txt 'q'

Each newline-terminated inbox line is sent followed by '\n'; a partial line waits for its newline. The inbox is consumed by offset, so
the file may be appended to at any time. Stop with Ctrl+C or by writing the
line '__quit__'.
"""
from __future__ import annotations

import argparse
import datetime as dt
import time
from pathlib import Path

import serial


def stamp() -> str:
    return dt.datetime.now().isoformat(timespec="milliseconds")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM10")
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--log", type=Path, default=Path("build/serial/session.log"))
    ap.add_argument("--inbox", type=Path, default=Path("build/serial/inbox.txt"))
    args = ap.parse_args()

    args.log.parent.mkdir(parents=True, exist_ok=True)
    args.inbox.parent.mkdir(parents=True, exist_ok=True)
    args.inbox.touch()
    offset = args.inbox.stat().st_size

    with serial.Serial(args.port, args.baud, timeout=0.05) as port, \
            args.log.open("a", encoding="utf-8", buffering=1) as log:
        log.write(f"{stamp()} # bridge open {args.port} {args.baud}\n")
        pending = b""
        inbox_carry = b""  # partial inbox line; dispatched only once its newline arrives
        while True:
            data = port.read(4096)
            if data:
                pending += data
                while b"\n" in pending:
                    line, pending = pending.split(b"\n", 1)
                    log.write(f"{stamp()} < {line.decode('utf-8', 'replace').rstrip()}\n")
            size = args.inbox.stat().st_size
            if size > offset:
                with args.inbox.open("rb") as f:
                    f.seek(offset)
                    chunk = f.read(size - offset)  # bytes appended after the size check wait for the next poll
                offset += len(chunk)
                inbox_carry += chunk
                *complete, inbox_carry = inbox_carry.split(b"\n")
                for raw in complete:
                    cmd = raw.decode("utf-8", "replace").strip("\r")
                    if cmd == "__quit__":
                        log.write(f"{stamp()} # bridge quit\n")
                        return
                    if cmd:
                        port.write(cmd.encode() + b"\n")
                        log.write(f"{stamp()} > {cmd}\n")
            if not data:
                time.sleep(0.02)


if __name__ == "__main__":
    main()
