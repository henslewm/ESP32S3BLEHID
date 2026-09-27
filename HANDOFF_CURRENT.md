# Current Handoff

## Where things stand (2026-09-27)

The ESP32-S3 now pairs with WINSTONDESKTOP as a BLE keyboard and mouse. Windows can remove and re-add it automatically.

- **Mouse fix.** Core 3.3.12 silently dropped the second HID input report (same UUID 0x2A4D). `hid_core_workaround.cpp` registers it. Hardware now shows `connected=yes keyboard_sub=yes mouse_sub=yes`, HID Keyboard Device plus HID-compliant mouse in Windows, `t` PASS and no resets. [Record](evidence/mouse-fix-2026-09-27.md).
- **Automatic pairing.** `powershell.exe -File scripts/Invoke-BleAutoPair.ps1 -BleAddress 7C:4F:AD:21:52:89 -Unpair -Pair` exits 0. It opens the device by exact address and accepts Just Works in-process (ConfirmOnly helper). After a reset or `B`/`b`, the bonded host reconnects on its own.
- **Modular firmware.** Start at [MODULES.md](firmware/BLEScanner_WORKING_v7/MODULES.md) and open only the owning module. The charter now requires this (the rule is pending re-approval).
- **Build and flash:**
  - Compile with `arduino-cli compile -b esp32:esp32:esp32s3:CDCOnBoot=cdc --build-path build/<id> --output-dir build/<id>-out firmware/BLEScanner_WORKING_v7`.
  - Upload with `-p COM10`.
  - Serial runs through `python scripts/serial_bridge.py --port COM10 --log build/serial/<id>.log`; append commands to `build/serial/inbox.txt` and send `__quit__` before uploading.
  - Current flashed build: `v7-split-diag4-pio` (PlatformIO; see below).

## PlatformIO

The root `platformio.ini` builds this sketch with Arduino 3.3.12 through pioarduino `55.03.312-1`. Use `pio run -e dev -t upload` (the port is selected by USB ID). Rules are in `docs/PLATFORMIO.md`. The flashed build is now `v7-split-diag4-pio` (ELF `55a30baf…52c1`). Template issue #51 and PR #52 carry the sanitized write-up and the rules. Placeholder values are in ignored `build/local-identifiers.ps1`.

## Open

1. The user re-approves the foundation (`python scripts/bootstrap_gate.py activate`) for the modular-code charter rule. The gate is inactive until then.
2. The operator visually confirms that `t` moves the cursor. Agent cursor sampling was swamped by real mouse motion.
3. Commit/push, issue #1 update and an upstream core bug report are all unperformed and need authority.
4. Keyboard input beyond neutral reports stays out of scope under the current charter. Scripted automation of real work needs a charter revision.
5. The telemetry comparison and cross-family acceptance review (ESP-007) remain.

Locked baseline SHA-256 `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6` is unchanged. The working sketch now differs by design (split plus fixes).
