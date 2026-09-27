# ESP-007 cross-family acceptance review packet (2026-09-27)

- **Implementer family:** Anthropic (Claude). **Reviewer family:** OpenAI (Codex), via `@codex review` on the PR that adds this file.
- **Reviewed source:** `main` at `4439543`. The firmware sources are unchanged since `b30d71f`, whose runtime `elf_sha256=52e09739…a8c3` the operator flashed and tested.
- **Scope:** the reviewer verifies each claim below against the cited files as they stand at the PR head, not only this diff.
- **Out of scope:** hardware observations (C3 subscriptions, cursor motion) are operator attestations recorded in the logs. A model cannot verify them; the reviewer checks only that the cited logs say what is claimed.
- **Mechanism:** a whole-firmware review against the charter checklist, not the acceptance ledger. `scripts/acceptance.py` would need `config/acceptance.json`, packets in `work/tasks` and schema-bound hardware evidence records, none of which exist for this already-merged work (ESP-ADR-019).

Paths below are relative to `firmware/BLEScanner_WORKING_v7/` unless stated.

| # | Criterion (`PROJECT_CHARTER.md` definition of done and constraints) | Claim | Where to verify |
|---|---|---|---|
| C1 | Locked baseline SHA-256 `9f3c9099…14c6` unchanged | The baseline evidence file is untouched; the working sketch was split from it by line range | `evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino`, `scripts/split_v7_sketch.py` (hash check at load) |
| C2 | Quiet boot to `READY HIDDIAG-v7`; `h` help; `b` enters HID mode without reset; host sees `S3-HID-KM-v7` | The boot banner is the only boot output at the default log level; `b` builds GATT once and advertises | `BLEScanner_WORKING_v7.ino:98`, `hid_mode.cpp:162`, `commands.cpp:142`, root `platformio.ini` `[env:dev]` (`CORE_DEBUG_LEVEL=1`) |
| C3 | `q` reports `connected=yes keyboard_sub=yes mouse_sub=yes` (operator-observed) | Flags are set from CCCD subscribe callbacks for each report characteristic | `commands.cpp:155-157`, `hid_mode.cpp:34`, `hid_mode.cpp:38`, `evidence/hardware-2026-09-27/main-b30d71f.log` |
| C4 | `t` refuses before `mouse_sub=yes`, sends mouse report 2 only, no keyboard report, no reset | Aborts if not connected or not subscribed; sends only 4-byte mouse payloads; `sendNeutralKeyboardReport()` is defined but never called | `hid_mode.cpp:279`, `hid_mode.cpp:283`, `hid_mode.cpp:290`, `hid_mode.cpp:226`, PASS line in `main-b30d71f.log` |
| C5 | Scanner return and original commands intact | Command set `h 1-4 p s i m v r d a u k x + - b B t q` unchanged; leaving HID mode disconnects the host and scanning resumes | `commands.cpp` (`handleCommand`), `hid_mode.cpp:199`, `evidence/hardware-2026-09-27/diag3.log` (scan reports after `1`/`2`) |
| C6 | Evidence separates source checks, compilation and operator observation; artifact bound by ELF hash | The runtime `elf_sha256` equals the flashed ELF; the manifest lists build and ELF hashes | `evidence/mouse-fix-2026-09-27.md`, `evidence/hardware-2026-09-27/manifest.json`, `hid_diag.cpp` (`printBuildIdentity`) |
| C7 | Constraints: `manufacturer()` before `setValue`; no report ID in GATT values; no `clearDuplicateCache()`; no Bluedroid-only APIs; pinned 3.3.12 / NimBLE | Manufacturer characteristic is created before its value is set; payloads are 8/4 bytes without IDs; banned names appear only in the header comment listing APIs it avoids | `hid_mode.cpp:116`, `hid_mode.cpp:181`, `BLEScanner_WORKING_v7.ino:13-17`, `config.h:15` |
| C8 | Workaround correctness | The second 0x2A4D report matches core `inputReport()`: READ\|NOTIFY, 0x2908 `{2, 0x01}`, inserted before `startServices()`; version-tied and documented | `hid_core_workaround.cpp:25-36`, `hid_mode.cpp:133-142`, core `libraries/BLE/src/BLEHIDDevice.cpp:162-193` (3.3.12), `MODULES.md` |
| C9 | Modular rule | Every module is listed in `MODULES.md`; headers are contracts; the `.ino` holds only `setup()`/`loop()` | `MODULES.md`, `BLEScanner_WORKING_v7.ino` |

**Upstream:** the core defect behind C8 is reported as [espressif/arduino-esp32#12951](https://github.com/espressif/arduino-esp32/issues/12951), with a minimal repro captured on this board.
