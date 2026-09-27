# ESP32 v7 preparation and first engineering task

Prepared 2026-09-27. This is planning material, not a dispatch or approval. The canonical future worker contract must be finalized and validated through WORK_PACKET_PROTOCOL.md before an execution worker is reserved/dispatched. No worker may widen it. The existing setup interpreter does not have `jsonschema`, which the packet tools require; select an existing suitable environment or obtain authority for installing the pinned dependency before packet validation. Bootstrap/project validators use only the standard library and already run. No dependency was installed during preparation.

## Prepared inputs

- The owner's exact hash-pinned baseline and handoff are preserved in `evidence/baseline-v7/`; Downloads originals are untouched.
- `archive/handoff-import-2026-09-27/` preserves the script and its input bundle. Never rerun its force-copy operations against an existing evidence destination.
- The editable target is the single `.ino` under `firmware/BLEScanner_WORKING_v7/`; its initial bytes match the baseline.
- `evidence/import-manifest-2026-09-27.json` inventories exact file hashes and origins.
- Core source: `C:/Users/hensl/AppData/Local/Arduino15/packages/esp32/hardware/esp32/3.3.12/libraries/BLE/src`.
- CLI executable: `C:/Program Files/Arduino CLI/arduino-cli.exe`. Presence was checked; no new compilation or physical-device action has run.

## First bounded task: descriptor validity only

After ACTIVE validation, select a maintained HID descriptor parser or a narrowly validated parser implementation from a primary source. Record its name, version/revision and provenance; do not claim a parser is installed or vetted merely because Python exists. Inspect the immutable source to locate the exact report-map array and any conditional compilation affecting it. Extract its bytes without editing firmware.

Produce an auditable hex/binary dump, source file hash and source offsets, parser invocation/version/output, and a decoded report table containing top-level collections, usages, report IDs, input/output/feature kinds, bit lengths, padding, signed ranges and expected GATT payload lengths. Preserve exact parser errors and offsets. Compare every input byte consumed to the extracted map and cross-check report-size/count calculations. Report validity separately from host compatibility: a valid descriptor alone does not explain a Windows subscription outcome.

Allowed outputs are descriptor-analysis artifacts and the minimal reproducible extraction/validation helper needed for them. No firmware changes, advertising changes, pairing, serial access, input reports, toolchain upgrade or baseline mutation belong to this task. If ambiguity requires core inspection, record the dependency and return it to the architect rather than silently changing task scope. A parser failure is evidence to investigate, not authority to change the map.

Acceptance checks: repeatable extraction bound to the baseline hash; every descriptor byte accounted for; parser/tool provenance; report IDs and lengths explicitly documented; failures retained; baseline hash unchanged; no claim of hardware success. Arrange the exact machine validation command when selecting the parser and finalize the canonical contract before dispatch.

## Subsequent dependency order

1. Audit `inputReport(1)` and `inputReport(2)` in exact Arduino-ESP32 3.3.12/NimBLE source: notify properties and Report Reference descriptors; then the full required HID service.
2. Inspect primary Windows HOGP/composite requirements and compare the findings. Do not change the report map until the owner's required inspection is complete.
3. Prepare observation-only subscription/connection/security logging; compile the copied sketch with pinned core, explicit board options, workspace-contained outputs/cache and exact ELF/build metadata.
4. Identify physical board/unit/COM port and Windows build; prepare concrete operator-authorized pairing/connection observations without input.
5. Only after fresh `connected=yes`, `keyboard_sub=yes` and `mouse_sub=yes`, authorize and run mouse-only `t`, then scanner return. Stop on reset and retain the final checkpoint/backtrace with the exact ELF.

## Readiness limits

The board revision/unit/COM, Windows build, board menu options, eligible acceptance reviewer and correct project remote are still unobserved. Their gates apply when the corresponding milestone requires them. They are not silently guessed to finish setup. No budget, model provider, Git publication or hardware authority is supplied by this document.

## Preparation change inventory

Updated active controls: `README.md`, `PROJECT_CHARTER.md`, `PROJECT_STATE.md`, `OPEN_LOOPS.md`, `DECISIONS.md` (append only), `FACTS_AND_ASSUMPTIONS.md`, `SOURCE_INDEX.md`, `RISK_REGISTER.md`, `HANDOFF_CURRENT.md`, `CHANGELOG.md`, `CONNECTOR_PLAN.md`, `SKILL_PLAN.md`, `DOMAIN_PROFILE.md`, and `config/project.json`. Their prior versions were copied to `archive/template-control-2026-09-27/` before tailoring.

Added configuration/planning: `config/intake-esp32-v7.json`, `config/bootstrap.json`, `BOOTSTRAP_REVIEW.md`, and this preparation document. Added evidence records: `evidence/import-manifest-2026-09-27.json`, `evidence/bootstrap-validation-2026-09-27.txt`, `evidence/preparation-review-2026-09-27.md`, and `evidence/baseline-v7/IMPORT_RECORD.md`. The import manifest enumerates every original, staged, preserved and working bundle file with its exact path/hash. The editable sketch is `firmware/BLEScanner_WORKING_v7/BLEScanner_WORKING_v7.ino`.

No changes were made to the Downloads originals, `archive/BLEScanner.ino`, the pre-existing `scripts/Invoke-BleAutoPair.ps1`, native skill copies, Git remote, or HEAD. No commit or push occurred.
