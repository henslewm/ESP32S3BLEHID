# Current Handoff

## Current direction

On 2026-09-27 the user requested documentation, commit/push and a new mouse issue so subsequent chat branches can work on smaller pieces. This closeout preserves the current work; it does not continue firmware or hardware investigation. Wazuh and VM lab remain deferred.

The user clarified that the earlier PowerShell pop-up question was not a stop instruction and rejected unauthorized master-file edits. Their targeted rollback is complete. The approved Write-Output 'background-check' returned exit 0, but its window behavior was not separately confirmed. Use captured output and hidden child helpers; do not claim the console issue is fixed. No new goals or requirements were approved through that episode.

## Next mouse chat

Start with [mouse issue #1](https://github.com/henslewm/ESP32S3BLEHID/issues/1) and [docs/MOUSE_INVESTIGATION.md](docs/MOUSE_INVESTIGATION.md). The unresolved observation is q twice reporting `mode=yes connected=yes keyboard_sub=yes mouse_sub=no` after the operator's manual Settings action. [Exact operator text](evidence/operator-serial-q-2026-09-27.md).

The suggested first small slice is the existing descriptor/report-reference audit: parse v7's map, trace keyboard ID 1 and mouse ID 2 through the exact core/GATT construction, and return evidence plus one bounded next experiment proposal. [Reference review](evidence/hid-reference-review-2026-09-27.md) covers combo/Hijel construction, Bit Pirate v1.6 report corrections and USB/BLE/Classic distinctions. No replacement library was selected.

Some running serial instrumentation is absent from the preserved source; exact flashed artifact and type99 meaning remain unknown. Establish build identity before attributing a code finding to the operator's device.

## Implementation and evidence

- Pairing CLI/module: `scripts/Invoke-BleAutoPair.ps1`, `scripts/BlePairing.psm1`. Exact-address AEP selection, native unpair, bounded Windows pairing, cancellation/reconciliation and structured outcomes.
- Telemetry CLI/module: `scripts/Invoke-BlePairingJournal.ps1`, `scripts/BlePairingTelemetry.psm1`. Local categorical comparison with process/fragment/coverage checks and ten-second tails. Real comparison remains pending.
- Software: 40 passing PS5.1/Pester 3.4 tests, existing-file WinRT bridge, prior read-only collector and synthetic journal smoke. [Validation record](evidence/pairing-validation-2026-09-27.md); not hardware acceptance.
- [Actual discovery](evidence/local-discovery-2026-09-27.md): E_ACCESSDENIED in the sandbox, desktop queries time out at 30 seconds. No agent PairAsync/UnpairAsync occurred. Selected raw results are tracked under `evidence/discovery-2026-09-27/`; other build output remains ignored.
- Original pairing script: `archive/Invoke-BleAutoPair.before-repair-2026-09-27.ps1`, preserving CRLF bytes; its LF-normalized content matches the original staged Git blob `c14d9ed72f4809e3415b8ba4e6b7515bb72992c6`.

Locked/working v7 SHA-256 remains `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`; older archive SHA-256 remains `310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580`. No firmware edit, build, agent serial command, flash or HID input occurred. Follow the existing charter: t remains mouse-only and requires fresh mouse_sub=yes.

## Foundation and publication

ACTIVE validation passed under Winston's carried approval for fingerprint `e0e761e7c553168d736883930d282a074856095928ed7e45e82c091397b630b2`. This closeout does not change bound architecture documents. README records the existing fallback Python. No installation occurred. A future execution worker still needs its validated packet/environment; the mouse issue is investigation intake, not a dispatched packet.

Prepared on main from `508764d`. At the user's request, [henslewm/ESP32S3BLEHID](https://github.com/henslewm/ESP32S3BLEHID) was created and verified private with ADMIN access; origin now points there. Implementation/evidence checkpoint [43281a2](https://github.com/henslewm/ESP32S3BLEHID/commit/43281a201e1879c06ed054bfc27a04f14e911b7a) was pushed to main and verified by GitHub branch readback. Mouse issue [#1](https://github.com/henslewm/ESP32S3BLEHID/issues/1) is OPEN, with its body verified against the prepared text. This follow-up links those receipts. No write to the inherited template repository occurred.

Suggested opening instruction for the next chat: "Work on issue #1's first descriptor/report-reference audit slice. Read the current handoff and issue, inspect source only, and return findings plus one bounded next experiment proposal."
