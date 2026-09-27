# Open Loops

| ID | Priority | Item | Owner | Next action | Dependency | Due | Status |
|---|---|---|---|---|---|---|---|
| ESP-001 | High | Foundation approval | User | Run `bootstrap_gate.py activate` for the fingerprint that adds the modular-code charter rule | Charter edited 2026-09-27 | Before next autonomous session | Pending re-approval (FE1.1s exclusion approval completed) |
| ESP-002 | High | Descriptor validation | — | Superseded: the report map was valid; the defect was GATT registration | — | — | Closed by root cause ([record](evidence/mouse-fix-2026-09-27.md)) |
| ESP-003 | High | Core GATT and Windows HOGP audit | — | Root cause: core 3.3.12 drops duplicate-UUID characteristics; workaround in `hid_core_workaround.cpp` | — | — | Completed |
| ESP-004 | High | Subscription/security observations | — | `hid_diag` logs handles, encryption and every subscribe; the exact builds are hashed | — | — | Completed |
| ESP-005 | High | Mouse-only diagnostic and scanner regression | Operator | Visually confirm cursor motion from `t`; everything else observed | Fresh `mouse_sub=yes` observed | Next session | Awaiting operator visual confirmation |
| ESP-006 | High | Publish checkpoint and mouse issue | — | Done in the previous session | — | 2026-09-27 | Completed |
| ESP-007 | Medium | Independent hardware acceptance | Integrator | Arrange eligible cross-family review; no implicit waiver | Reviewable implementation and evidence now exist | Before acceptance | Pending |
| ESP-008 | Medium | Packet validation environment | Codex/user | Find or authorize the pinned jsonschema dependency before worker dispatch | — | Before worker dispatch | Pending; no installation performed |
| ESP-009 | High | Fresh exact-device pairing acceptance | — | `Invoke-BleAutoPair.ps1 -Unpair -Pair` exit 0 with both subscriptions | — | — | Completed |
| ESP-010 | Medium | Scripted/manual telemetry comparison | Operator | Resume local comparison when wanted; the scripted pairing path now works | — | Not fixed | Deferred by user |
| ESP-011 | Medium | Publish this session's work | User | Authorize commit/push and an issue #1 update | — | — | Awaiting authority |
| ESP-013 | Medium | Template adoption | User | Review and merge henslewm/universal-ai-project-template PR #52 after a Codex review of its head | Issue #51 posted | — | PR open |
| ESP-012 | Low | Upstream core bug report | User | Optionally report the duplicate-UUID drop to espressif/arduino-esp32 | External write authority | — | Proposed |

Inherited template-development loops are preserved in `archive/template-control-2026-09-27/OPEN_LOOPS.md` and do not control the ESP32 task queue.
