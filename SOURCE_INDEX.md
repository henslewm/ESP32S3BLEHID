# Source Index

| ID | Source | Location | Authority and verification | Limits |
|---|---|---|---|---|
| ESP-SRC-001 | Owner v7 handoff | evidence/baseline-v7/CODEX_CLI_HANDOFF_BLEScanner_v7.md | User's scope, guardrails and historical observations; copied unchanged 2026-09-27 | Hardware observations not independently reproduced |
| ESP-SRC-002 | Exact v7 source | evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino | SHA-256 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6; 61,594 bytes | Immutable evidence, not completed HID |
| ESP-SRC-003 | Import bundle and provenance | archive/handoff-import-2026-09-27; evidence/import-manifest-2026-09-27.json; evidence/baseline-v7/IMPORT_RECORD.md | Downloads originals, staging and outputs hashed; exact staged script executed against fresh output | Script has overwrite flags and is unsafe to rerun into preserved destinations |
| ESP-SRC-004 | Older repository sketch | archive/BLEScanner.ino | SHA-256 310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580; preserved | Not v7; do not substitute for locked source |
| ESP-SRC-005 | Installed Arduino core | C:/Users/hensl/AppData/Local/Arduino15/packages/esp32/hardware/esp32/3.3.12 | Directory, BLE source file paths and platform.txt version 3.3.12 inspected 2026-09-27 | Function implementation audit and resolved build recipe still pending |
| ESP-SRC-006 | Installed CLI | C:/Program Files/Arduino CLI/arduino-cli.exe | Executable path found 2026-09-27 | No compile/upload/device discovery performed |
| ESP-SRC-007 | Arduino sketch build process | https://docs.arduino.cc/arduino-cli/sketch-build-process/ | Official documentation retrieved 2026-09-27; Pre-Processing section specifies concatenation of sketch-folder .ino files | Supports isolated working-sketch layout only; not ESP32 runtime proof |
| ESP-SRC-008 | Repository governing procedures | MASTER_INSTRUCTIONS.md; BOOTSTRAP_PROTOCOL.md; .agents/skills/complex-project-bootstrapper/SKILL.md; templates/software-hardware/PROFILE.md | Current local setup, approval and hardware-evidence rules | Generic permission defaults specialized by current charter/profile; no authority from inherited task history |
| ESP-SRC-009 | Git and runtime inspection | main at 508764d; README fallback interpreter | Local git status/log/remote and successful Python bootstrap/project-tool execution 2026-09-27 | Origin is template remote; no publication; jsonschema absent from this interpreter |
| ESP-SRC-010 | Independent preparation review | evidence/preparation-review-2026-09-27.md | Read-only agent review of source identity and inactive preparation | Same model family; not cross-family hardware acceptance |

## Pairing and telemetry sources verified 2026-09-27

- ESP-SRC-011: [Microsoft pairing sample](https://learn.microsoft.com/en-us/samples/microsoft/windows-universal-samples/deviceenumerationandpairing/), [FindAllAsync](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformation.findallasync), [UnpairAsync](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformationpairing.unpairasync?view=winrt-26100). AEP requirement and exact APIs; not proof this device pairs successfully.
- ESP-SRC-012: [PowerShell 5.1 logging](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging?view=powershell-5.1), [4104 fragments](https://devblogs.microsoft.com/powershell/powershell-the-blue-team/), [Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon). Researcher verified installed 4104 fields, ProcessGuid, UTC and image hash semantics. Enabled channels do not prove complete logging.
- ESP-SRC-013: [Wazuh collection](https://documentation.wazuh.com/current/user-manual/capabilities/log-data-collection/configuration.html). Local collection and forwarding are separate; no ingestion/alerts validated.
- ESP-SRC-014: `evidence/pairing-validation-2026-09-27.md`, `tests/BlePairing.Tests.ps1`, `tests/BlePairingTelemetry.Tests.ps1`. Software checks and host preflight; mocked/synthetic results are not hardware acceptance. Full primary-source list in `docs/BLE_PAIRING.md`.
- ESP-SRC-015: `evidence/operator-serial-i-b-B-2026-09-27.md`. User-pasted serial output confirms reported Own BLE address `7C:4F:AD:21:52:89` and advertising start/stop sequence. Exact firmware artifact, COM and capture time remain unbound; no Windows pairing proof.
- ESP-SRC-016: `evidence/local-discovery-2026-09-27.md` and its ignored raw-result paths. Actual bounded local discovery errors/timeouts, repaired cancellation output and 40 passing tests; user confirms Settings visibility. [Microsoft AQS selector guidance](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/build-a-device-selector) verified 2026-09-27. No scripted pairing acceptance.

## Operator observations and reference review

- ESP-SRC-017: [Exact user q observation](evidence/operator-serial-q-2026-09-27.md), supplied 2026-09-27: connected=yes, keyboard_sub=yes, mouse_sub=no twice. Unbound to an exact flashed artifact. The user's clarification about unauthorized master edits and the inferred shell hold is preserved in ESP-ADR-008/009. The later publication/small-issue instruction is ESP-ADR-010.
- ESP-SRC-018: [HID reference review](evidence/hid-reference-review-2026-09-27.md), public primary sources read 2026-09-27: TheNitek/A-box combo, Hijel keyboard/mouse implementation, Bit Pirate v1.6, HIDForge and Espressif. Source links and limits are retained there. No compiled compatibility proof, firmware migration or confirmed root cause.
- ESP-SRC-019: [Discovery artifact manifest](evidence/discovery-2026-09-27/manifest.json) and [40-test result](evidence/pairing-tests-2026-09-27.json). Byte-identical selected copies from ignored local output, preserved for the publication checkpoint; not successful hardware acceptance.
- ESP-SRC-020: [Publication checkpoint checks](evidence/closeout-validation-2026-09-27.md) and [fresh 40-test result](evidence/pairing-tests-closeout-2026-09-27.json). Current software/hash/gate checks and verified private repository identity; hardware limitations remain explicit.

## Planned technical sources, not yet relied upon for a HID finding

Inspect exact Arduino-ESP32 3.3.12 BLEHIDDevice/NimBLE source against Espressif upstream; retrieve relevant USB-IF HID, Bluetooth SIG HIDS/HOGP and Microsoft Learn host documentation during the approved investigation. Record exact versions, URLs and sections when retrieved. The descriptor parser has not yet been selected or validated.

Inherited template source records are preserved in archive/template-control-2026-09-27/SOURCE_INDEX.md. They are not ESP32 technical evidence.

## Mouse root cause and pairing sources (2026-09-27, this session)

- ESP-SRC-021: Installed core `libraries/BLE/src/BLEService.cpp:252-282` (addCharacteristic duplicate-UUID drop under NimBLE), `:540-650` (GATT table built from the characteristic map), `BLEUUID.cpp` `equals()` (cross-length comparison through `toString`), `BLEServer.cpp:864-888` (subscribe dispatch to `m_notifyChrVec` only). Read locally at 3.3.12.
- ESP-SRC-022: [Hardware record](evidence/mouse-fix-2026-09-27.md) plus `evidence/hardware-2026-09-27/` (serial logs, pairing JSON results, build/ELF hashes). Agent-run with user authority; cursor motion confirmed by the operator on `main` `b30d71f` (`main-b30d71f.log`).
- ESP-SRC-023: NimBLE `ble_gap.h` (esp32s3-libs 3.3.12): `ble_gap_event_listener_register`, `BLE_GAP_EVENT_SUBSCRIBE` fields, `BLE_GAP_SUBSCRIBE_REASON_*`.
- ESP-SRC-024: Reference review by a read-only agent: [TheNitek BleComboKeyboard.cpp](https://raw.githubusercontent.com/TheNitek/ESP32-NimBLE-Combo/master/BleComboKeyboard.cpp), [Bit Pirate BluetoothService.cpp](https://raw.githubusercontent.com/geo-tp/ESP32-Bit-Pirate/main/src/Services/BluetoothService.cpp), [Espressif esp_hid_device](https://raw.githubusercontent.com/espressif/esp-idf/master/examples/bluetooth/esp_hid_device/main/esp_hid_device_main.c), [Microsoft HID transports](https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/hid-transports). Summarized fetches; byte comparisons unverified; not relied on for the root cause.
- ESP-SRC-025: [pioarduino releases](https://github.com/pioarduino/platform-espressif32/releases) (tag 55.03.312-1 = Arduino v3.3.12 / ESP-IDF v5.5.5, read 2026-09-27 via gh api); esptool 5.3.1 `flash-id` on the board (ESP32-S3 QFN56 v0.2, 16 MB flash, embedded 8 MB PSRAM AP_3v3); installed core `boards.txt` menu options for the arduino-cli equivalent.
