# Facts, Assumptions and Unknowns

## Verified facts

- The Downloads v7 source, preserved locked copy and isolated working sketch have SHA-256 `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`.
- Older `archive/BLEScanner.ino` is different: SHA-256 `310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580`.
- The preparation script copies local files with overwrite flags, validates afterward and creates a working copy if absent. It does not perform hardware actions or enforce a filesystem lock. It was run only against a fresh destination after source-hash verification.
- Core 3.3.12 and Arduino CLI paths exist. No fresh compile or resolved backend verification has run.
- Setup was unactivated at startup. The user plan explicitly carried Winston's approval of the unchanged foundation; gate activation recorded it and ACTIVE validation passed. The user subsequently authorized documentation, commit/push and a focused mouse issue, then requested a new private repository. henslewm/ESP32S3BLEHID was created, verified private and configured as origin; the template repository was not modified.
- Host is WINSTONDESKTOP, Windows build 26200; Windows PowerShell 5.1.26100.9549 and Pester 3.4.0 were used for validation. Sysmon channel is missing and WazuhSvc stopped as of read-only 2026-09-27 preflight.
- The previous pairing script used the default discovery kind and a fallback; Microsoft requires AssociationEndpoint for pairing. Fixing this confirmed defect does not prove the reported native Failed result is resolved.
- Tests mocked BLE wrappers; existing-file WinRT and read-only event collector checks used no Bluetooth operations. Synthetic journal results are not device evidence.

## Owner-supplied observations

Latest user output reports Central CONNECTED and keyboard notifications SUBSCRIBED. The user explicitly issued q twice; both report mode=yes connected=yes keyboard_sub=yes mouse_sub=no. This confirms the observed subscription asymmetry persists. No mouse diagnostic is authorized by those values.

The preserved handoff reports compile/boot/scanner success, the HID construction workaround, keyboard-only subscription and a mouse-only diagnostic. These remain supplied history until reproduced against an exact build.

On 2026-09-27 the operator supplied fresh serial i/b/B text: NimBLE, Own BLE address `7C:4F:AD:21:52:89` (printed type 99), advertising started then stopped by uppercase B. See `evidence/operator-serial-i-b-B-2026-09-27.md`. This confirms the operator-reported address and command observations; it does not establish Windows pairing or mouse subscription.

The operator then confirmed advertising restart and visibility in Windows Settings. Agent native discovery remained bounded/time-limited without an exact AEP result; no PairAsync/UnpairAsync was invoked. Supplied serial instrumentation is absent from the preserved source, so type99 meaning and exact flashed artifact remain unknown. The subsequent q observations are preserved in evidence/operator-serial-q-2026-09-27.md; Windows final pairing status remains unconfirmed.

## Approved defaults

High risk because firmware and host input need independent review; private handling; no fixed deadline. Retain existing model entrypoints and available resources without installations. Approval identity is Winston, explicitly carried by the user plan. Hardware operations and external writes retain their applicable gates.

## Unknowns

Exact board/unit/COM, flashed build and pairing/security state remain unconfirmed. The Windows host/build are recorded above. Descriptor validity, GATT layout and root cause await the ordered investigation. Record board menu settings, build recipe and exact ELF during the first approved build cycle. An eligible independent reviewer and fresh hardware evidence are required before hardware acceptance. No completed HID claim is made.
