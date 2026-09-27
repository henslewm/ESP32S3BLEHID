# Project State

- **Status:** ACTIVE — approved foundation
- **Updated:** 2026-09-27 session close; all work merged to origin/main (PRs #2-#7, #9, #10).
- **Current task:** mouse issue #1 resolved on hardware and operator-confirmed on `main` `b30d71f` (ESP-005 Completed); phase 2 foundation (ESP-ADR-020) approved and ACTIVE, fingerprint 4f53ec2d….

## Verified state

- **Mouse root cause found and fixed.** Arduino-ESP32 3.3.12 `BLEService::addCharacteristic` silently drops a second characteristic with the same UUID under NimBLE. The mouse input report (0x2A4D, ID 2) never reached the GATT table (handle 65535). A sketch-side workaround (`hid_core_workaround.cpp`) registers it without core, backend, report-map or payload changes. [Record](evidence/mouse-fix-2026-09-27.md).
- **Hardware (arduino-cli builds diag1-3, then PlatformIO builds; the latest flashed build printed `elf_sha256` equal to its ELF):**
  - `q`: `connected=yes keyboard_sub=yes mouse_sub=yes`.
  - Windows shows HID Keyboard Device and HID-compliant mouse.
  - `t` passes with no reset.
  - Scanner return works.
  - Bonded reconnect after reset and after `B`/`b` is automatic.
  - Cursor motion from `t` confirmed by the operator on `main` `b30d71f` (elf_sha256 `52e09739…`).
- **Automatic pairing works.** `Invoke-BleAutoPair.ps1 -Unpair -Pair` exits 0. It uses exact-address `FromBluetoothAddressAsync` (about 50 ms) and in-process ConfirmOnly custom pairing (`scripts/BleCustomPairing.cs`), with no UI. The earlier `FindAllAsync` timeout and plain `PairAsync` failure are explained and replaced. 44/44 Pester tests pass.
- **Fixed a pre-existing v7 bug:** `B` and the scan presets left Windows connected. `stopHidMode` now disconnects the host.
- **Firmware split into modules.** The sketch is now 14 modules listed in [MODULES.md](firmware/BLEScanner_WORKING_v7/MODULES.md), split mechanically from the locked baseline by `scripts/split_v7_sketch.py`. The unsplit and split builds are string-equivalent. The locked baseline SHA-256 `9f3c9099…14c6` is unchanged. The working sketch no longer matches it by design.
- **Modular-code rule added** to `PROJECT_CHARTER.md` (constraints) and `.claude/rules/05-modular-code.md`, at the user's direction. The charter is hash-bound; the foundation was re-approved (ACTIVE, fingerprint 20fc20c2…).
- FE1.1s USB hub integration is explicitly out of scope (ESP-ADR-012; renewed approval recorded).
- Tooling: `scripts/serial_bridge.py` holds COM10, logs, and sends newline-terminated commands appended to `build/serial/inbox.txt`. Build with `pio run -e dev` (`platformio.ini`, pioarduino 55.03.312-1); see `docs/PLATFORMIO.md`.
- **Artifact identity:** the firmware prints its embedded `elf_sha256`, and evidence binds to it. The generated build-label script was removed at the user's direction (ESP-ADR-018).

## Next

1. Foundation re-approval is complete (ESP-001); validate the gate each session with `python scripts/validate_bootstrap.py config/bootstrap.json --require-active`.
2. Cursor motion confirmed. No keyboard report is sent by any diagnostic, so there is no stuck-key risk.
3. Issue #1 closed with a resolution note; core duplicate-UUID bug filed upstream as espressif/arduino-esp32#12951 (ESP-012). Cross-family Codex review (ESP-007) done in PR #10 (C1-C9); unmet charter deliverables tracked as #11 (descriptor parser output) and #12 (Windows HOGP primary sources).
4. Keyboard input beyond neutral reports is still out of scope until the charter is revised.
