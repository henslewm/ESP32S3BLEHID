# Pairing tooling verification — 2026-09-27

Evidence level: software/static/mocked contract checks and read-only local telemetry. **No live BLE pairing acceptance and no completed HID claim.** The user-supplied history reports fallback discovery followed by native `Failed`; fixing the AEP kind does not resolve that observation without a fresh run.

## Environment and authorization

- WINSTONDESKTOP, Windows build 26200, Windows PowerShell 5.1.26100.9549, installed Pester 3.4.0. No tool installation.
- User plan explicitly carried Winston's existing approval of the unchanged foundation. Activated through the existing interactive gate; ACTIVE validation passed for `e0e761e7c553168d736883930d282a074856095928ed7e45e82c091397b630b2`. No material architecture/bound-document changes.
- Python on PATH is absent. Used the existing interpreter documented in README for bootstrap and project validation.

## Checks

- `powershell.exe -NoProfile -File scripts/Test-BlePairing.ps1`: **38 passed, 0 failed**. Includes PS5.1 parsing, exact address/duplicate/missing-property behavior, already-paired refresh, failed unpair, successful unpair/re-pair ordering, consent cancellation, timeout, actual pending-task late completion, unknown concurrent operation and postcheck exception preservation.
- Tests also cover observer contamination, EventData PID/GUID vs provider PID, PID reuse/creation UTC, uncertain lifetimes, fragmented/conflicting 4104 records, missing/disabled/denied coverage, rollover/reset/unread tail, unrelated Bluetooth events and exact device links.
- Real `StorageFile.GetFileFromPathAsync` test against the existing module verified AsTask projection and reflected IAsyncInfo cancellation. It performs no Bluetooth calls.
- CLI usage returned 0; invalid address and missing mutation address returned 2, with no native calls.
- Read-only collector smoke completed normally and collected 19 local PowerShell events. It retained missing/disabled channel metadata and an unread-tail gap. Local output: `build/pairing-development/collector-4c413818e9d444e7ab66e2c7f6c0f86e/`.
- Synthetic full Scripted/Manual/Compare orchestration passed in isolated ignored copies with every pairing entry point replaced. Ten-second tails verified; no Settings action occurred. Fixture directory: `build/pairing-development/synthetic-journal-aef7324bb5e54c9798216f67f92af35d/`. These synthetic successes must never be treated as real pairing.
- `python scripts/validate_project.py`: passed, 81 required paths. ACTIVE bootstrap validation and `git diff --check` also passed at closeout.
- Locked and working v7 SHA-256: `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`. Older archived sketch: `310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580`. All unchanged.

The original Pester NUnit export attempted a restricted WMI query and failed after all tests passed. The test runner now records Pester's returned counts directly, without changing permissions or using WMI. The subsequent normal runner completed successfully. Detailed test JSON is under ignored `build/pairing-development/`.

## Independent review and repairs

Bounded read-only reviewers checked pairing and telemetry. Findings repaired and covered by regression tests: actual PS5.1 IAsyncInfo cancellation, OperationAlreadyInProgress uncertainty, mutation evidence before fallible postcheck, preflight hashes/result paths, late completion timestamps, Sysmon UTC/process lifetime matching, final-drain gaps, friendly-name/suffix false links, manual marker timing and uncertainty-aware classifications. Reviewers confirmed no outstanding findings in their final bounded passes. These same-family software reviews do not satisfy future independent hardware acceptance.

The end-to-end fixture also exposed PS5.1 Start-Process exit metadata loss. The journal now retains the live handle and records uncertainty if exact exit metadata is unavailable. Both synthetic modes and comparison passed after that fix.

## Limitations and next evidence

Fresh local preflight found `Microsoft-Windows-Sysmon/Operational` missing and `WazuhSvc` stopped. Bluetooth/UserPnp channel availability is mixed. No policy, service or Wazuh configuration was altered; no ingestion or alert claim is supported. Collector polling and finite windows can have gaps, preserved explicitly.

At the initial software-check stage, target address and advertising confirmation were pending. Subsequent operator output supplied the address and advertising/Settings visibility; live discovery failed or timed out. Two later q readings showed connected=yes, keyboard_sub=yes, mouse_sub=no. See [local-discovery-2026-09-27.md](local-discovery-2026-09-27.md) and [operator-serial-q-2026-09-27.md](operator-serial-q-2026-09-27.md). Follow-up regression tests reached 40 passed, 0 failed, retained in [pairing-tests-2026-09-27.json](pairing-tests-2026-09-27.json).

Scripted pairing, the real telemetry comparison and mouse acceptance remain unresolved. No agent serial command, firmware flash, t or PairAsync/UnpairAsync was performed. Never infer that Windows unpair erased ESP32 bonds. Publication was later explicitly authorized as a separate closeout task; this record describes the earlier validation stage.

## Files changed by this implementation session

- `scripts/Invoke-BleAutoPair.ps1`
- `scripts/BlePairing.psm1`
- `scripts/Invoke-BlePairingJournal.ps1`
- `scripts/BlePairingTelemetry.psm1`
- `scripts/Test-BlePairing.ps1`
- `tests/BlePairing.Tests.ps1`
- `tests/BlePairingTelemetry.Tests.ps1`
- `docs/BLE_PAIRING.md`
- `evidence/pairing-validation-2026-09-27.md`
- `config/bootstrap.json` (activation receipt only)
- `PROJECT_STATE.md`, `OPEN_LOOPS.md`, `FACTS_AND_ASSUMPTIONS.md`, `DECISIONS.md`, `SOURCE_INDEX.md`, `RISK_REGISTER.md`, `HANDOFF_CURRENT.md`, `CHANGELOG.md`, `README.md`

Ignored build outputs retain local collector evidence and synthetic fixtures. For publication, selected discovery/test evidence was copied into tracked evidence files; the pre-repair pairing script was preserved at `archive/Invoke-BleAutoPair.before-repair-2026-09-27.ps1`. Its LF-normalized content matches the original staged Git blob `c14d9ed72f4809e3415b8ba4e6b7515bb72992c6`; the archive retains the original CRLF bytes. Pre-existing preparation changes were retained. The implementation began from `508764d` on main; current publication state is recorded in PROJECT_STATE.md and HANDOFF_CURRENT.md.
