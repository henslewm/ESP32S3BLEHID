# Open Loops

| ID | Priority | Item | Owner | Next action | Dependency | Due | Status |
|---|---|---|---|---|---|---|---|
| ESP-001 | High | Foundation approval | Winston/Codex | Preserve unchanged foundation; validate ACTIVE each session | Existing Winston approval carried by current user plan; receipt recorded through gate | 2026-09-27 | Completed |
| ESP-002 | High | Descriptor validation | Codex | Extract and parse every byte; retain offsets, collections, IDs and lengths | ACTIVE | Not fixed | Pending |
| ESP-003 | High | Core GATT and Windows HOGP audit | Codex | Verify references, notify properties, mandatory characteristics and primary host requirements | ESP-002 | Not fixed | Pending |
| ESP-004 | High | Subscription/security observations | Codex/operator | Prepare no-input diagnostics; retain build/ELF; identify board, COM and Windows version | ESP-003 and concrete hardware authority | Not fixed | Pending |
| ESP-005 | High | Mouse-only diagnostic and scanner regression | Operator | Observe both subscriptions, run t, verify reset-free movement and scanner return | ESP-004; fresh mouse_sub=yes | Not fixed | Pending |
| ESP-006 | High | Publish checkpoint and mouse issue | Codex | Commit/push validated checkpoint and open focused issue | User requested new private henslewm/ESP32S3BLEHID; created, privacy checked, origin updated | Current closeout | Publication pending; no template-origin writes |
| ESP-007 | Medium | Independent hardware acceptance | Integrator | Arrange eligible cross-family review; no implicit waiver | Reviewable implementation/evidence | Before acceptance | Pending |
| ESP-008 | Medium | Packet validation environment | Codex/user if installation needed | Find a suitable existing environment or authorize the pinned jsonschema dependency; finalize/validate first contract before dispatch | Current setup Python lacks jsonschema | Before worker dispatch | Pending; no installation performed |
| ESP-009 | High | Fresh exact-device pairing acceptance | Operator/Codex | Retain discovery failures; schedule exact-device confirmation separately from the focused mouse source audit | Address/Settings visibility confirmed; q twice connected=yes, keyboard_sub=yes, mouse_sub=no | Not fixed | Mouse subscription still absent; scripted discovery unresolved |
| ESP-010 | Medium | Scripted/manual telemetry comparison | Operator | Resume local comparison after immediate pairing investigation | ESP-009; manual Settings markers | Not fixed | Local tooling retained; Wazuh/VM lab deferred by user |

Inherited template-development loops are preserved in `archive/template-control-2026-09-27/OPEN_LOOPS.md` and do not control the ESP32 task queue.
