# ESP32-S3 BLE Scanner / HID Research

Start with [PROJECT_STATE.md](PROJECT_STATE.md) and [HANDOFF_CURRENT.md](HANDOFF_CURRENT.md). The unchanged [foundation](BOOTSTRAP_REVIEW.md) is ACTIVE under Winston's carried approval. Validate the gate each session.

Windows pairing and telemetry tooling is documented in [BLE_PAIRING.md](docs/BLE_PAIRING.md). Exact-device pairing (ESP-009) and mouse subscription/cursor motion (ESP-005) are operator-confirmed. Run `powershell.exe -NoProfile -File scripts/Test-BlePairing.ps1` for software checks without Bluetooth actions.

[Mouse issue #1](https://github.com/henslewm/ESP32S3BLEHID/issues/1) is closed; root cause and fix are in [evidence/mouse-fix-2026-09-27.md](evidence/mouse-fix-2026-09-27.md), and the core bug is filed upstream as espressif/arduino-esp32#12951.

- Locked source: [evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino](evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino). Never modify or overwrite it.
- Editable sketch: [firmware/BLEScanner_WORKING_v7/BLEScanner_WORKING_v7.ino](firmware/BLEScanner_WORKING_v7/BLEScanner_WORKING_v7.ino). Split into modules; differs from the baseline by design.
- Owner handoff: [evidence/baseline-v7/CODEX_CLI_HANDOFF_BLEScanner_v7.md](evidence/baseline-v7/CODEX_CLI_HANDOFF_BLEScanner_v7.md).
- Import provenance: [evidence/baseline-v7/IMPORT_RECORD.md](evidence/baseline-v7/IMPORT_RECORD.md).

Expected SHA-256: `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`.

Target: ESP32-S3 Dev Module, `esp32:esp32:esp32s3`, Arduino-ESP32 `3.3.12`, built-in NimBLE, serial `921600`.

Build only the isolated working sketch directory. The preserved script output has multiple full `.ino` copies and is not a build target. Keep `t` mouse-only and wait for fresh `mouse_sub=yes` before running it.

The private project remote is [henslewm/ESP32S3BLEHID](https://github.com/henslewm/ESP32S3BLEHID), created at the user's request. This checkout retains inherited template Git history, but no ESP32 work is published to `henslewm/universal-ai-project-template`. Inherited template controls are preserved under `archive/template-control-2026-09-27/` and do not define this project's task queue.

Python is not on PATH. Setup was validated with this existing interpreter (recheck availability in future sessions):

```powershell
& 'C:\Users\hensl\Documents\GitHub\_acceptance-demo-10\review-2\.python-runtime\cpython-3.12-windows-x86_64-none\python.exe' -B scripts/validate_project.py
```

The activation receipt is in `config/bootstrap.json`; the review file remains the pre-approval proposal. Material foundation changes require renewed review through the gate.
