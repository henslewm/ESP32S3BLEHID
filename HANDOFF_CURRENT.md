# Current Handoff

## Where things stand (2026-09-27 session close)

The ESP32-S3 pairs with the Windows host as a BLE keyboard and mouse, and Windows can remove and re-add it automatically. All work is merged to `main` on origin (PRs #2–#7, #9, #10).

- **Mouse fix.** Core 3.3.12 silently dropped the second HID input report (same UUID 0x2A4D). `hid_core_workaround.cpp` registers it. Hardware shows `connected=yes keyboard_sub=yes mouse_sub=yes`, HID Keyboard Device plus HID-compliant mouse in Windows, `t` PASS and no resets. [Record](evidence/mouse-fix-2026-09-27.md).
- **Automatic pairing.** `powershell.exe -File scripts/Invoke-BleAutoPair.ps1 -BleAddress <address> -Unpair -Pair` exits 0 (exact-address lookup plus in-process ConfirmOnly pairing). The bonded host reconnects on its own after a reset or `B`/`b`.
- **Modular firmware.** Start at [MODULES.md](firmware/BLEScanner_WORKING_v7/MODULES.md) and open only the owning module.
- **Artifact identity.** The `i` command prints `elf_sha256=`, the ELF hash embedded in the app image. It equalled the flashed ELF exactly. Evidence binds to that value. `FIRMWARE_BUILD_ID` is only an optional `-D` label; the generated-label script was removed at the user's direction after seven review rounds on it.
- **Build and flash.**
  - Build and upload with `pio run -e dev -t upload`: root `platformio.ini`, pioarduino `55.03.312-1` = Arduino 3.3.12, port matched by USB ID. Rules are in `docs/PLATFORMIO.md`; an arduino-cli equivalent is documented there too.
  - Serial: `python scripts/serial_bridge.py --port COM10 --log build/serial/<name>.log`. Append commands to `build/serial/inbox.txt`, and send `__quit__` before uploading.

## Open

1. **Foundation re-approval.** Completed: the bootstrap gate is `ACTIVE` (charter modular rule plus profile build section), approved by Winston 2026-09-27, fingerprint 20fc20c2… in `config/bootstrap.json`.
2. **Cursor motion from `t`.** Confirmed by the operator on `main` `b30d71f`.
3. **Issue #1 and upstream.** Issue #1 is closed with a resolution note. The core bug is reported as espressif/arduino-esp32#12951.
4. **Charter scope.** Keyboard input beyond neutral reports stays out of scope. Scripted automation of real work needs a charter revision.
5. **Remaining items.** The telemetry comparison. Cross-family review (ESP-007) is done (PR #10). Unmet charter deliverables: #11 (descriptor parser output) and #12 (Windows HOGP primary sources). The pre-existing CI failure (ESP-014, `test_bootstrap_in_place`) is fixed; the test skips outside a template checkout and CI is green.
6. **Template follow-ups.** Template PR #52 is merged. Any Codex findings from its final review are tracked in a new template issue linked from ESP-013.

Locked baseline SHA-256 `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6` is unchanged. The working sketch differs by design (split plus fixes). Placeholder values for the public template issue are in ignored `build/local-identifiers.ps1`.
