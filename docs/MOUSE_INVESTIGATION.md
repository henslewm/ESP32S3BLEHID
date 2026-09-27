# Mouse subscription investigation handoff

## Problem

On WINSTONDESKTOP, the operator's ESP32-S3 advertises as `S3-HID-KM-v7` at reported address `7C:4F:AD:21:52:89`. Following a manual Windows Settings action, two serial `q` readings showed:

```text
mode=yes connected=yes keyboard_sub=yes mouse_sub=no
```

The mouse behavior remains unresolved. The connection/subscription observation does not establish final Windows bonding status or scripted pairing success.

## Evidence to read

- [Exact operator q observation](../evidence/operator-serial-q-2026-09-27.md).
- [Operator i/b/B observation](../evidence/operator-serial-i-b-B-2026-09-27.md).
- [Local discovery attempts](../evidence/local-discovery-2026-09-27.md) and [retained raw results](../evidence/discovery-2026-09-27/manifest.json).
- [Reference implementation review](../evidence/hid-reference-review-2026-09-27.md).
- [Pairing software checks](../evidence/pairing-validation-2026-09-27.md).

The user wants a focused mouse issue and smaller chat branches. The issue is an investigation entry point, not an execution-worker dispatch or a replacement for the existing charter.

## Suggested first small slice

Use the existing descriptor/GATT audit work in ESP-002 and ESP-003:

1. Parse the preserved v7 HID report-map bytes and report the collections, report IDs, bit lengths and offsets.
2. Trace keyboard ID 1 and mouse ID 2 through the exact Arduino-ESP32 3.3.12 HID/input-report implementation and the working sketch. Check the report-reference descriptors, notify properties and subscription callbacks.
3. Compare the relevant construction with the reviewed implementations and primary Windows HOGP requirements. Return concrete findings and one bounded next experiment proposal.

That first slice can finish with a source-backed diagnosis or an explicit remaining uncertainty. It does not need to fix scripted discovery, complete telemetry work, or replace the entire firmware. Establish the running source/build identity before attributing a source finding to the operator's flashed device: some serial instrumentation is absent from the preserved sketch.

## Existing boundaries

Preserve the scanner, serial command meanings, report interface, approved core/backend and locked source. The working sketch remains byte-identical to the baseline at this checkpoint. Expected SHA-256:

```text
9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6
```

Use [PROJECT_CHARTER.md](../PROJECT_CHARTER.md) for the existing acceptance criteria and authority. In particular, `t` remains mouse-only and requires fresh `mouse_sub=yes`; no automatic HID input or firmware/backend migration is included. Wazuh, VM lab and the scripted/manual telemetry comparison remain deferred. The current closeout performs documentation/publication only; hardware operations belong to a separately scoped continuation.

## Eventual mouse acceptance

The existing charter requires fresh exact-build observations of connected=yes, keyboard_sub=yes and mouse_sub=yes, followed by the operator-authorized mouse-only diagnostic and scanner regression. Source inspection, successful compilation, connection alone or mocked pairing tests do not close the mouse issue.
