# Project State

- **Status:** ACTIVE; software tooling verified, mouse hardware acceptance unresolved.
- **Updated:** 2026-09-27; branch main, checkpoint prepared from `508764d`.
- **Current task:** the user authorized documentation, commit/push and a new mouse issue so subsequent chat branches can work on smaller pieces.

## Verified state

- Locked and working v7 SHA-256: `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`. The sketches are unchanged; no firmware experiment, build, flash, agent serial command or HID input occurred.
- The unchanged foundation is ACTIVE under Winston's carried approval, fingerprint `e0e761e7c553168d736883930d282a074856095928ed7e45e82c091397b630b2`.
- Exact-address AEP pairing/native unpair and local scripted/manual telemetry tooling are implemented. **40 PS5.1/Pester 3.4 tests passed**. Existing-file WinRT, read-only collector and synthetic journal checks are software evidence, not device acceptance. See [validation](evidence/pairing-validation-2026-09-27.md).
- WINSTONDESKTOP is Windows build 26200. The operator reported address `7C:4F:AD:21:52:89`, restarted advertising and confirmed Windows Settings visibility.
- Live scripted discovery failed with E_ACCESSDENIED in the sandbox and timed out in desktop/default, exact-address and MTA attempts. **No agent PairAsync/UnpairAsync was reached.** [Tracked discovery evidence](evidence/local-discovery-2026-09-27.md).
- After the manual Settings action, the operator issued q twice: **connected=yes, keyboard_sub=yes, mouse_sub=no**. [Exact observation](evidence/operator-serial-q-2026-09-27.md). Final Windows pairing status and exact flashed artifact remain unconfirmed; some serial instrumentation is absent from the preserved source.
- The user's library/tool survey was reviewed against public sources. [Findings](evidence/hid-reference-review-2026-09-27.md) support a focused composite HID audit; no dependency/backend migration was adopted.
- Sysmon was missing and WazuhSvc stopped during earlier preflight. Wazuh, VM lab and real telemetry comparison remain deferred. No logging/service configuration changed.
- Unauthorized master-file additions and the inferred blanket shell hold were removed at the user's direction. The background-check command returned exit 0; silence/focus behavior was not independently confirmed. MASTER_INSTRUCTIONS.md and MASTER_CODEX.md have no remaining changes from that episode.

## Publication

The user explicitly requested a new private repository after the destination check. Created and verified [henslewm/ESP32S3BLEHID](https://github.com/henslewm/ESP32S3BLEHID) with isPrivate=true and ADMIN access; origin now points there. [Checkpoint 43281a2](https://github.com/henslewm/ESP32S3BLEHID/commit/43281a201e1879c06ed054bfc27a04f14e911b7a) was pushed to main and read back from GitHub. [Mouse issue #1](https://github.com/henslewm/ESP32S3BLEHID/issues/1) is OPEN and its posted body matches the prepared handoff. No template repository write occurred. These navigation updates are a follow-up to the implementation checkpoint.

## Next focused work

Use [mouse issue #1](https://github.com/henslewm/ESP32S3BLEHID/issues/1) and [MOUSE_INVESTIGATION.md](docs/MOUSE_INVESTIGATION.md) as the next chat's entry point. The suggested first slice is the existing descriptor/report-reference audit. Keep scripted discovery and telemetry findings separate from the mouse subscription problem. The current closeout does not perform hardware work.

Python is absent from PATH; README records the existing fallback. Its missing jsonschema matters before future execution-worker dispatch, not for creating this investigation issue. Inherited template controls are archived and do not define the ESP32 task queue.
