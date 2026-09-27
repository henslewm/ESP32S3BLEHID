# Codex CLI Handoff — ESP32-S3 BLE Scanner / HID Research

## Locked baseline

**Do not modify or overwrite the baseline file.**

- Baseline source: `BLEScanner_LOCKED_BASELINE_v7.ino`
- SHA-256: `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`
- Target board: ESP32-S3 Dev Module / ESP32-S3-WROOM-1 family
- FQBN: `esp32:esp32:esp32s3`
- Arduino-ESP32 core: `3.3.12`
- BLE backend: built-in NimBLE
- Serial baud: `921600`
- Baseline boot banner: `READY HIDDIAG-v7. h=help`
- HID advertised name: `S3-HID-KM-v7`

## Current verified state

The baseline has reached the following working state:

1. Compiles for `esp32:esp32:esp32s3` under Arduino-ESP32 3.3.12.
2. Uses the core's NimBLE backend rather than the earlier Bluedroid-only extended-scan API.
3. Boots idle and does not flood Serial until commanded.
4. BLE scanner functionality remains interactive.
5. HID service construction no longer crashes.
6. The Arduino-ESP32 3.3.12 `BLEHIDDevice::manufacturer(String)` null-pointer issue is worked around by first creating the manufacturer characteristic with `manufacturer()` and then setting its value.
7. HID GATT input reports are defined for keyboard report ID 1 and mouse report ID 2.
8. HID diagnostic command `t` is deliberately mouse-only and sends no keyboard modifier reports.
9. HID subscription state is tracked separately for keyboard and mouse.
10. Composite HID advertises as Generic HID (`0x03C0`) rather than Keyboard-only (`0x03C1`).
11. PnP identity no longer impersonates a Microsoft USB vendor ID. It uses Bluetooth SIG vendor source with Espressif company ID `0x02E5`.
12. Windows pairing currently reaches HID advertising/service setup. The next unresolved issue is that Windows has been observed subscribing to the keyboard input report but not the mouse input report.

## Current serial commands

- `1` active BLE scan, quiet
- `2` passive BLE scan, quiet
- `3` active BLE scan, verbose
- `4` passive BLE scan, verbose
- `p` pause/resume
- `s` print summary
- `i` system/BLE info
- `m` toggle periodic summaries
- `v` toggle per-packet output
- `r` toggle raw hex
- `d` toggle AD decoding
- `u` toggle duplicates/restart
- `k` recycle scan/results
- `x` clear statistics
- `+/-` RSSI print threshold
- `b` enter BLE HID mode
- `B` stop BLE HID mode
- `t` mouse-only HID diagnostic
- `q` HID connection/subscription status
- `h` / `?` help

## Guardrails for Codex

1. Treat `BLEScanner_LOCKED_BASELINE_v7.ino` as immutable evidence/baseline.
2. Make all experiments in a copy or branch.
3. Do not remove working scanner functionality while debugging HID.
4. Do not reintroduce Bluedroid-only APIs unless the toolchain is intentionally changed.
5. Do not call `BLEScan::clearDuplicateCache()` on Arduino-ESP32 3.3.12; its declaration/link implementation mismatch caused a linker failure.
6. Do not call `BLEHIDDevice::manufacturer("...")` before the manufacturer characteristic exists.
7. Do not prepend report IDs to GATT input characteristic values. The report ID is represented by the Report Reference descriptor for `inputReport(id)`.
8. Keep `t` mouse-only until Windows reliably subscribes to the mouse characteristic.
9. Do not send Ctrl/Shift/Alt/GUI test reports while HID notification stability is unresolved.
10. Preserve the quiet boot behavior.
11. Prefer small, testable changes and record each result.
12. Before changing the report map, inspect the Arduino-ESP32 3.3.12 BLEHIDDevice/NimBLE implementation and Windows HOGP expectations.

## Immediate next engineering question

Determine why Windows subscribes to keyboard report ID 1 but not mouse report ID 2.

Investigate in this order:

1. Validate the HID report descriptor byte-for-byte with an HID descriptor parser.
2. Verify both `inputReport(1)` and `inputReport(2)` have correct Report Reference descriptors and notify properties under Arduino-ESP32 3.3.12 NimBLE.
3. Verify the HID service includes the expected Protocol Mode, HID Information, Report Map, Control Point, and both input reports.
4. Determine whether Windows requires a different composite HOGP layout or separate top-level collection/report arrangement.
5. Log subscription callbacks and connection/security state without sending any HID input.
6. Only after `mouse_sub=yes`, run the mouse-only `t` diagnostic.
7. If a reset occurs, capture the last serial checkpoint and decode any backtrace against the exact ELF.

## Acceptance criteria before advancing

- Board boots to `READY HIDDIAG-v7. h=help`.
- `b` starts HID mode without reset.
- Windows sees `S3-HID-KM-v7`.
- Windows connects without reset.
- `q` reports `connected=yes`.
- `keyboard_sub=yes`.
- `mouse_sub=yes`.
- `t` produces mouse movement only.
- No keyboard modifier becomes stuck.
- ESP32 does not reset during `t`.
- Returning to scan mode still works.

## Do not call this finished yet

The code is a **locked working baseline**, not a completed HID implementation. The unresolved mouse subscription issue is the next target.
