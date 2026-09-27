# Changelog

## 2026-09-27 — PlatformIO build and template hand-off

- Adapted the user's `platformio.ini` (original archived): pioarduino `55.03.312-1` for Arduino 3.3.12, `src_dir` set to the sketch, quiet `dev` log level, 921600 monitor. Board confirmed N16R8 by esptool. Build `v7-split-diag4-pio` flashed and passed the hardware smoke test with 8 MB PSRAM visible.
- Added PlatformIO rules: `docs/PLATFORMIO.md`, `.claude/rules/06-platformio.md` and a `DOMAIN_PROFILE.md` Build configuration section (bound, so re-approval is needed). Verified the arduino-cli equivalent compiles.
- Posted sanitized template issue henslewm/universal-ai-project-template#51 and opened PR #52 (not merged) adding the modular-code and PlatformIO rules to the template. Placeholder values are kept locally in ignored `build/local-identifiers.ps1`.

## 2026-09-27 — mouse fixed, automatic pairing, modular firmware

- Excluded FE1.1s USB hub integration in the charter (ESP-ADR-012); renewed approval recorded.
- Split the working sketch into 14 modules with `MODULES.md`, generated from the locked baseline by `scripts/split_v7_sketch.py`. Added a modular-code charter rule and `.claude/rules/05-modular-code.md`. The charter change needs re-approval.
- Root cause of `mouse_sub=no`: core 3.3.12 silently drops the second 0x2A4D input report. Fixed with `hid_core_workaround.cpp`. Added observation-only `hid_diag` (build ID, handles, GAP subscribe/encryption log).
- `stopHidMode` now disconnects the host (a pre-existing bug left Windows connected).
- Pairing script: exact-address lookup plus in-process ConfirmOnly custom pairing (`BleCustomPairing.cs`); fixed WinRT property-bag access. 44/44 Pester tests pass.
- Hardware (COM10): both subscriptions, HID keyboard and mouse devices present, `t` PASS, scanner return, automatic reconnect, and automatic unpair/re-pair exit 0. Added `scripts/serial_bridge.py`. [Record](evidence/mouse-fix-2026-09-27.md).

## 2026-09-27 — publication checkpoint and focused mouse handoff

- User authorized documenting, committing and pushing the current work and opening a mouse issue for smaller chat continuations. Verified that the inherited origin is the template and requested the correct destination before publication.
- User then requested a new private repository. Created henslewm/ESP32S3BLEHID, verified privacy/ADMIN access and updated origin; no template repository write occurred.
- Preserved the exact two q readings, source-backed library review, six original discovery artifacts with hashes, the 40-test result and the original staged pairing script.
- Consolidated current state and the mouse handoff, distinguishing source/software checks, actual discovery failures and operator subscription observations. No firmware changes or new device operations.
- Restored the master files after the unauthorized additions; documented the successful one-line execution test without claiming it was windowless.
- Adapted the inherited CI closeout check to validate this project's ACTIVE foundation instead of checking that a generated project is identical to the distributable template. Existing Python tests remain in the workflow.
- Fresh 40-test PS5.1 run, project/ACTIVE validators and protected source hashes passed. Added Git attributes to preserve evidence/import bytes across clones; retained the fresh test receipt.
- Published implementation/evidence checkpoint 43281a2 to the private project and verified remote main at the same SHA. Opened and read back mouse issue #1, then linked the issue and checkpoint from the continuation documents.

## 2026-09-27 — correction of unauthorized instruction edits

- Removed the agent-added MASTER_INSTRUCTIONS.md section and two MASTER_CODEX.md bullets after the user explicitly approved their rollback. The original edits were not authorized by the user's behavioral instruction.
- Recorded q twice showing connected=yes, keyboard_sub=yes, mouse_sub=no after the manual Settings action.
- Corrected records that treated the user's pop-up question as a stop instruction. Preserved the actual pop-up report and serial evidence. The latest user instruction authorizes only the correction and one background-check command, then stopping for further context. No firmware edit or device operation occurred.

## 2026-09-27 — operator address and local pairing focus

- Preserved operator serial i/b/B output and confirmed reported address 7C:4F:AD:21:52:89. The transcript ends with advertising stopped by B.
- Updated state and next action to restart lowercase b before exact-address discovery; deferred Wazuh and VM lab per user steering. No firmware or hardware operation performed by the agent.
- Follow-up: operator confirmed restart and Settings visibility. Read-only native discovery timed out; fixed cancellation null-output corruption and added exact-address AQS filtering, with 40 tests passing. No agent pair/unpair was attempted. All subsequent PowerShell launches hidden per user request; manual pairing/q outcome requested.

## 2026-09-27 — pairing tooling and telemetry comparison

- Activated the unchanged foundation using Winston's approval explicitly carried by the user plan; ACTIVE validation passed.
- Replaced name/fallback selection and PnP removal with exact-address AEP pairing/native unpair, bounded cancellation/reconciliation, structured evidence and exit codes.
- Added scripted/manual local telemetry journals, ten-second tails, categorical comparison, process/GUID correlation, 4104 reconstruction and explicit channel limitations.
- Added 38 PS5.1/Pester 3.4 tests, read-only collector smoke and synthetic end-to-end journal checks. Preserved all firmware/baseline hashes and prior staged work.
- Live exact-device pairing, real comparison and mouse subscription remain pending. No firmware, serial, BLE operation, logging configuration, Git publication or external communication was performed.

## 2026-09-27 — v7 handoff and inactive ESP32 foundation

- Verified supplied baseline hash and preserved Downloads originals.
- Executed a byte-identical staged handoff script into a fresh evidence folder; isolated the editable sketch without firmware changes.
- Archived template controls and tailored project charter, plans, intake, review, state, sources, risks and handoff.
- Recorded inherited remote mismatch, fallback Python and distinction between historical hardware claims and current file checks.
- No activation, compile, serial/pairing/upload, HID input, commit or push occurred. Engineering awaits exact foundation approval.
