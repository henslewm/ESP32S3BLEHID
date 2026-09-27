# Bootstrap Foundation Review

State: AWAITING_APPROVAL — autonomy is OFF until explicit activation.
Profile: software-hardware
Architecture fingerprint: `e0e761e7c553168d736883930d282a074856095928ed7e45e82c091397b630b2`

## Charter

```json
{
  "name": "ESP32-S3 BLE Scanner / HID Research",
  "objective": "Determine and resolve why Windows subscribes to keyboard report ID 1 but not mouse report ID 2 while preserving the locked v7 baseline, quiet boot, and working interactive BLE scanner.",
  "definition_of_done": [
    "Locked baseline SHA-256 remains 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6.",
    "Board boots quietly to READY HIDDIAG-v7. h=help; b enters HID mode without reset; Windows sees S3-HID-KM-v7 and connects without reset.",
    "q reports connected=yes, keyboard_sub=yes, and mouse_sub=yes in a recorded hardware run.",
    "Only after mouse_sub=yes, t produces mouse movement only, with no stuck keyboard modifiers and no ESP32 reset.",
    "Returning to scan mode still works; original interactive scanner commands remain available.",
    "Evidence distinguishes source checks, compilation, and operator-observed hardware results; any backtrace is decoded against the exact run's ELF."
  ],
  "non_goals": [
    "Keyboard injection or modifier testing, unrelated devices, scanner redesign, and declaring HID complete without every hardware acceptance observation.",
    "Changing BLE backend, framework, board family, security model, or public command/report interface without renewed architecture approval.",
    "Continuing the inherited universal-ai-project-template issue sequence or publishing to its remote."
  ],
  "constraints": [
    "Never modify or overwrite the locked baseline or Downloads originals. Experiments belong in firmware/BLEScanner_WORKING_v7 or a separate experiment copy.",
    "Preserve scanner functionality, all existing command meanings, and quiet boot.",
    "Pin Arduino-ESP32 3.3.12, built-in NimBLE, and esp32:esp32:esp32s3; do not reintroduce Bluedroid-only APIs or call BLEScan::clearDuplicateCache().",
    "Create BLEHIDDevice manufacturer characteristic with manufacturer() before setting its value; never prepend report IDs to GATT input values.",
    "Keep t mouse-only; no Ctrl/Shift/Alt/GUI test reports while notification stability is unresolved; no t before mouse_sub=yes.",
    "Before changing report map bytes, parse the existing descriptor and inspect the exact 3.3.12 implementation and primary Windows HOGP expectations.",
    "Use small testable changes and retain each result; a successful build is not hardware verification.",
    "No hardware operation, Windows pairing/cache changes, flash/erase, Git publication, communications, credential access, permissions changes, or toolchain migration without the applicable explicit authority.",
    "Preserve pre-existing archive/BLEScanner.ino and untracked scripts/Invoke-BleAutoPair.ps1; their presence does not authorize execution."
  ]
}
```

## Architecture and milestone dependency graph

```json
{
  "summary": "Retain immutable v7 source evidence and an isolated editable Arduino sketch. Investigate the existing descriptor first, then exact-core GATT construction, required HID service characteristics and Windows composite HOGP expectations. Add observation-only instrumentation before any approved HID movement test. The serial/Windows hardware boundary remains operator controlled.",
  "boundaries": [
    "Evidence: evidence/baseline-v7 and archive/handoff-import-2026-09-27 are preserved inputs, never experiment/build targets.",
    "Firmware: firmware/BLEScanner_WORKING_v7/BLEScanner_WORKING_v7.ino is the working copy; scanner commands and quiet idle boot are invariants.",
    "Descriptor/GATT: keyboard report 1 and mouse report 2 retain separate Report Reference descriptors; payloads exclude the report ID byte.",
    "Telemetry: subscription, connection and security observations must be obtainable without emitting HID input.",
    "Host: Windows pairing and physical firmware runs require an operator-authorized session; approval of local research alone does not authorize device state changes.",
    "Validation: static parser/source checks and pinned compilation precede operator-attested hardware results; exact artifacts and resets are traceable."
  ],
  "milestones": [
    "Preserve baseline and approve foundation",
    "Parse descriptor bytes",
    "Audit core GATT and Windows HOGP",
    "Prepare observation-only diagnostic",
    "Observe both subscriptions on hardware",
    "Verify mouse-only diagnostic and scanner return"
  ],
  "dependencies": [
    "Preserve baseline and approve foundation -> Parse descriptor bytes",
    "Parse descriptor bytes -> Audit core GATT and Windows HOGP",
    "Audit core GATT and Windows HOGP -> Prepare observation-only diagnostic",
    "Prepare observation-only diagnostic -> Observe both subscriptions on hardware",
    "Observe both subscriptions on hardware -> Verify mouse-only diagnostic and scanner return"
  ]
}
```

## Sources and evidence map

```json
[
  "Owner handoff of 2026-09-27; preserved at evidence/baseline-v7/CODEX_CLI_HANDOFF_BLEScanner_v7.md (historical hardware observations, not refreshed proof).",
  "C:/Users/hensl/Downloads/BLEScanner_FULL_CORRECTED_HIDDIAG_v7_GENERIC_HID.ino; verified SHA-256 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6; copied byte-for-byte to evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino.",
  "archive/handoff-import-2026-09-27/Prepare-BLEScanner-Codex-Handoff.ps1 and its adjacent preserved input bundle.",
  "C:/Users/hensl/AppData/Local/Arduino15/packages/esp32/hardware/esp32/3.3.12/libraries/BLE/src; official espressif/arduino-esp32 3.3.12 sources to be inspected before firmware changes.",
  "USB-IF HID descriptor specification, Bluetooth SIG HID Service/HOGP specifications, and Microsoft Learn HID documentation: primary sources to retrieve and cite during the approved investigation.",
  "Local repository at main 508764d; archive/BLEScanner.ino is an older baseline and is preserved separately."
]
```

## Risks

```json
[
  "Baseline overwrite or accidental compilation of duplicate full sketches: fresh destinations, hash verification and a separate single-sketch working directory.",
  "Host input or reset instability: retain mouse-only t gate and collect subscriptions/security before input; stop on reset and preserve exact ELF/logs.",
  "Historical success mistaken for fresh hardware proof: handoff observations remain owner supplied until reproduced and recorded.",
  "Wrong GitHub target: origin currently names henslewm/universal-ai-project-template; no publication or remote mutation is authorized by setup.",
  "Toolchain/source mismatch: verify actual recipes, core version, board options and resolved BLE implementation before drawing conclusions.",
  "Physical unit, COM port and exact Windows build have not been identified in this session; they must be recorded before hardware testing, not guessed."
]
```

## Routing and cost policy

```json
{
  "policy": "Use the current session's inherited model/resources for architecture and bounded read-only research; no paid provider, model installation or global configuration changes. Delegate independent scopes through the repository's agent roles. Future execution workers require canonical packets and EXECUTION_HARNESS_PROTOCOL.md. Hardware adapter/integration work is high risk and requires independent review and the profile's cross-family acceptance gate; absence of an eligible reviewer is a hold, not an implicit waiver. No worker performs hardware runs."
}
```

## GitHub workflow and routine permissions

```json
{
  "policy": "After exact foundation approval and successful ACTIVE validation, permit reversible local research, copied-sketch changes, local tests/compiles with outputs inside the workspace, and durable evidence updates within the stated scope. Follow ordered milestones and bounded work-packet/harness rules for delegated execution. Local Git reads are allowed; commits, remote changes, issue/PR writes, pushes and merges require their applicable authority. No current project GitHub write target is established. Retain template history as provenance without inheriting its old issue queue. Do not run pre-existing pairing scripts merely because they exist."
}
```

## Reserved human actions

```json
[
  "Explicit user approval of this exact architecture fingerprint through scripts/bootstrap_gate.py activate before autonomous substantive investigation.",
  "Operator identifies the physical ESP32 and host/COM port and authorizes the concrete hardware session before flash/erase, pairing/bond/cache changes or serial commands; t additionally requires freshly observed mouse_sub=yes.",
  "Owner approval for material changes to board/backend/core, security/authentication, report/command public interfaces or architecture boundaries; baseline immutability is mandatory.",
  "Explicit authority for Git publication/remote changes, communications, permissions, credentials, installations or external writes; no push to inherited template origin.",
  "Hardware acceptance requires recorded operator observations bound to the exact build and an eligible independent review; do not self-attest or invent reviewer waivers."
]
```

## Domain orientation

```json
{
  "baseline": "Hash-verified v7 is 61,594 bytes, SHA-256 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6, preserved under evidence/baseline-v7. Downloads source has the longer v7_GENERIC_HID filename. The older archive/BLEScanner.ino remains distinct; no firmware changes during bootstrap.",
  "hardware_identity": "Owner-specified ESP32-S3 Dev Module / ESP32-S3-WROOM-1 family, FQBN esp32:esp32:esp32s3, baseline v7. Exact physical board revision, unit identity and USB/COM mapping remain unobserved and are preconditions for an operator hardware session; local descriptor work does not depend on them.",
  "interfaces": "BLE scan and composite HID over GATT using the built-in NimBLE backend, keyboard input report ID 1 and mouse input report ID 2, advertised S3-HID-KM-v7 and Generic HID 0x03C0. Serial 921600; user handoff defines every command. No report IDs prepended to characteristic payloads.",
  "specifications": "Authoritative baseline is the owner's hash-pinned source. Implementation authority is installed Arduino-ESP32 3.3.12 BLE/NimBLE source and matching Espressif upstream. USB-IF HID, Bluetooth SIG HIDS/HOGP, and Microsoft Learn define the technical investigation sources; version/section details must be retrieved during the approved source audit before any report-map edit.",
  "environment": "Windows/PowerShell workspace. Core 3.3.12 directory and C:/Program Files/Arduino CLI/arduino-cli.exe are present, but no fresh build has run. Python is absent from PATH; existing CPython at C:/Users/hensl/Documents/GitHub/_acceptance-demo-10/review-2/.python-runtime/cpython-3.12-windows-x86_64-none/python.exe can run repository bootstrap validation. Exact host build, board menu options and resolved compile recipe await the relevant milestone.",
  "known_paths": "Owner handoff reports successful compile, quiet boot, interactive scanner, stable HID service construction and keyboard subscription; mouse subscription is unresolved. These historical observations have not been independently reproduced. This intake independently verifies file hashes and installed paths only.",
  "validation_resources": "Repository bootstrap/project validators, preserved source and installed core/CLI are available. A host-side descriptor parser must be selected and validated during the first approved engineering milestone; none has yet been verified. No simulator, current serial capture, exact run ELF or operator hardware evidence has been supplied. Hardware checks remain pending and separate from static/compile checks.",
  "physical_access": "The owner controls the physical unit and Windows host. No unit identity or current hardware session has been established; no serial opening, pairing, upload or HID input occurs during bootstrap. Confirm target and obtain concrete operator authority when the hardware milestone is ready.",
  "architecture_boundaries": "Locked baseline, scanner command behavior, quiet boot, board family/FQBN, Arduino-ESP32 3.3.12, built-in NimBLE, HID identity and report payload contracts, security policy and operator boundary are fixed. Investigate the existing map before proposing changes; material changes return to review."
}
```

## Unresolved blockers

```json
[]
```

## Project configuration and disclosed defaults

```json
{
  "project_name": "ESP32-S3 BLE Scanner / HID Research",
  "project_slug": "esp32s3blehid",
  "domain_profile": "software-hardware",
  "objective": "Determine and resolve why Windows subscribes to keyboard report ID 1 but not mouse report ID 2 while preserving the locked v7 baseline, quiet boot, and working interactive BLE scanner.",
  "problem_statement": "The owner reports a compiling and booting composite BLE HID baseline whose Windows mouse-input subscription remains unresolved. The existing repository is an unactivated template with an older archived sketch.",
  "owner": "Repository owner (hensl); approving identity must be supplied by the user",
  "risk_tier": "high",
  "sensitivity": "private",
  "target_date": "",
  "jurisdiction_or_version": "ESP32-S3 Dev Module; esp32:esp32:esp32s3; Arduino-ESP32 3.3.12; built-in NimBLE; serial 921600",
  "ai_clients": [
    "codex",
    "chatgpt",
    "claude",
    "claude-code"
  ],
  "connectors": [
    "web",
    "github"
  ],
  "connector_permissions": {
    "web": "read-only primary technical sources",
    "github": "read-only official upstream source; project publication disabled until owner identifies the correct remote and authorizes writes"
  },
  "success_criteria": [
    "Locked baseline SHA-256 remains 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6.",
    "Board boots quietly to READY HIDDIAG-v7. h=help; b enters HID mode without reset; Windows sees S3-HID-KM-v7 and connects without reset.",
    "q reports connected=yes, keyboard_sub=yes, and mouse_sub=yes in a recorded hardware run.",
    "Only after mouse_sub=yes, t produces mouse movement only, with no stuck keyboard modifiers and no ESP32 reset.",
    "Returning to scan mode still works; original interactive scanner commands remain available.",
    "Evidence distinguishes source checks, compilation, and operator-observed hardware results; any backtrace is decoded against the exact run's ELF."
  ],
  "deliverables": [
    "Hash-verified preserved handoff and baseline with provenance; isolated editable Arduino sketch.",
    "Byte-for-byte HID descriptor parser output and Arduino-ESP32 3.3.12 input-report/GATT implementation audit.",
    "Primary-source Windows HOGP findings and a small diagnostic experiment logging subscriptions and security without sending HID input.",
    "Bounded fixes, compile records, exact ELF/build metadata, operator hardware evidence, and current repository handoff."
  ],
  "source_locations": [
    "Owner handoff of 2026-09-27; preserved at evidence/baseline-v7/CODEX_CLI_HANDOFF_BLEScanner_v7.md (historical hardware observations, not refreshed proof).",
    "C:/Users/hensl/Downloads/BLEScanner_FULL_CORRECTED_HIDDIAG_v7_GENERIC_HID.ino; verified SHA-256 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6; copied byte-for-byte to evidence/baseline-v7/BLEScanner_LOCKED_BASELINE_v7.ino.",
    "archive/handoff-import-2026-09-27/Prepare-BLEScanner-Codex-Handoff.ps1 and its adjacent preserved input bundle.",
    "C:/Users/hensl/AppData/Local/Arduino15/packages/esp32/hardware/esp32/3.3.12/libraries/BLE/src; official espressif/arduino-esp32 3.3.12 sources to be inspected before firmware changes.",
    "USB-IF HID descriptor specification, Bluetooth SIG HID Service/HOGP specifications, and Microsoft Learn HID documentation: primary sources to retrieve and cite during the approved investigation.",
    "Local repository at main 508764d; archive/BLEScanner.ino is an older baseline and is preserved separately."
  ],
  "repeatable_workflows": [
    "Hash and provenance verification",
    "Descriptor and GATT contract inspection",
    "Pinned-toolchain compile with exact ELF retention",
    "Operator subscription log and scanner regression review"
  ],
  "output_formats": [
    "markdown",
    "json",
    "Arduino C++ source",
    "serial logs",
    "ELF and build metadata"
  ],
  "constraints": [
    "Never modify or overwrite the locked baseline or Downloads originals. Experiments belong in firmware/BLEScanner_WORKING_v7 or a separate experiment copy.",
    "Preserve scanner functionality, all existing command meanings, and quiet boot.",
    "Pin Arduino-ESP32 3.3.12, built-in NimBLE, and esp32:esp32:esp32s3; do not reintroduce Bluedroid-only APIs or call BLEScan::clearDuplicateCache().",
    "Create BLEHIDDevice manufacturer characteristic with manufacturer() before setting its value; never prepend report IDs to GATT input values.",
    "Keep t mouse-only; no Ctrl/Shift/Alt/GUI test reports while notification stability is unresolved; no t before mouse_sub=yes.",
    "Before changing report map bytes, parse the existing descriptor and inspect the exact 3.3.12 implementation and primary Windows HOGP expectations.",
    "Use small testable changes and retain each result; a successful build is not hardware verification.",
    "No hardware operation, Windows pairing/cache changes, flash/erase, Git publication, communications, credential access, permissions changes, or toolchain migration without the applicable explicit authority.",
    "Preserve pre-existing archive/BLEScanner.ino and untracked scripts/Invoke-BleAutoPair.ps1; their presence does not authorize execution."
  ],
  "out_of_scope": [
    "Keyboard injection or modifier testing, unrelated devices, scanner redesign, and declaring HID complete without every hardware acceptance observation.",
    "Changing BLE backend, framework, board family, security model, or public command/report interface without renewed architecture approval.",
    "Continuing the inherited universal-ai-project-template issue sequence or publishing to its remote."
  ],
  "domain": "software-hardware",
  "template_mode": false,
  "template_version": "1.0.0",
  "created": "2026-09-27"
}
```

## Bound document hashes

```json
{
  "PROJECT_CHARTER.md": "db74348b838e058c063ef2cec65c4950990217605ce35c5fff736397af0101f3",
  "CONNECTOR_PLAN.md": "45dbdbf4b6513e11517d7d383fcae540616e352ab380f8c380a1e26de96b6667",
  "SKILL_PLAN.md": "e14a47b63afe11db1ff7e9237373a20288ee068f79caa6896289dcee345319a4",
  "DOMAIN_PROFILE.md": "f8993afd9c350181d571514fcc9fb6445b39e5537d4467d0fff1e83f197ea74f"
}
```

## Readiness

- Ready for an explicit user decision.

## Bound document: PROJECT_CHARTER.md

# Project Charter

## Project

- **Name:** ESP32-S3 BLE Scanner / HID Research
- **Slug:** esp32s3blehid
- **Domain:** software-hardware
- **Jurisdiction / version:** ESP32-S3 Dev Module; esp32:esp32:esp32s3; Arduino-ESP32 3.3.12; built-in NimBLE; serial 921600
- **Risk tier:** high
- **Sensitivity:** private
- **Owner:** Repository owner (hensl); approving identity must be supplied by the user
- **Target date:** Not fixed

## Problem statement

The owner reports a compiling and booting composite BLE HID baseline whose Windows mouse-input subscription remains unresolved. The existing repository is an unactivated template with an older archived sketch.

## Desired outcome

Determine and resolve why Windows subscribes to keyboard report ID 1 but not mouse report ID 2 while preserving the locked v7 baseline, quiet boot, and working interactive BLE scanner.

## Definition of done

- Locked baseline SHA-256 remains 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6.
- Board boots quietly to READY HIDDIAG-v7. h=help; b enters HID mode without reset; Windows sees S3-HID-KM-v7 and connects without reset.
- q reports connected=yes, keyboard_sub=yes, and mouse_sub=yes in a recorded hardware run.
- Only after mouse_sub=yes, t produces mouse movement only, with no stuck keyboard modifiers and no ESP32 reset.
- Returning to scan mode still works; original interactive scanner commands remain available.
- Evidence distinguishes source checks, compilation, and operator-observed hardware results; any backtrace is decoded against the exact run's ELF.

## Required deliverables

- Hash-verified preserved handoff and baseline with provenance; isolated editable Arduino sketch.
- Byte-for-byte HID descriptor parser output and Arduino-ESP32 3.3.12 input-report/GATT implementation audit.
- Primary-source Windows HOGP findings and a small diagnostic experiment logging subscriptions and security without sending HID input.
- Bounded fixes, compile records, exact ELF/build metadata, operator hardware evidence, and current repository handoff.

## Scope

### In scope

- Work necessary to achieve the desired outcome and deliverables.

### Out of scope

- Keyboard injection or modifier testing, unrelated devices, scanner redesign, and declaring HID complete without every hardware acceptance observation.
- Changing BLE backend, framework, board family, security model, or public command/report interface without renewed architecture approval.
- Continuing the inherited universal-ai-project-template issue sequence or publishing to its remote.

## Constraints and approval gates

- Never modify or overwrite the locked baseline or Downloads originals. Experiments belong in firmware/BLEScanner_WORKING_v7 or a separate experiment copy.
- Preserve scanner functionality, all existing command meanings, and quiet boot.
- Pin Arduino-ESP32 3.3.12, built-in NimBLE, and esp32:esp32:esp32s3; do not reintroduce Bluedroid-only APIs or call BLEScan::clearDuplicateCache().
- Create BLEHIDDevice manufacturer characteristic with manufacturer() before setting its value; never prepend report IDs to GATT input values.
- Keep t mouse-only; no Ctrl/Shift/Alt/GUI test reports while notification stability is unresolved; no t before mouse_sub=yes.
- Before changing report map bytes, parse the existing descriptor and inspect the exact 3.3.12 implementation and primary Windows HOGP expectations.
- Use small testable changes and retain each result; a successful build is not hardware verification.
- No hardware operation, Windows pairing/cache changes, flash/erase, Git publication, communications, credential access, permissions changes, or toolchain migration without the applicable explicit authority.
- Preserve pre-existing archive/BLEScanner.ino and untracked scripts/Invoke-BleAutoPair.ps1; their presence does not authorize execution.

- Preserve authoritative source material and provenance.
- Keep secrets and unapproved restricted material out of Git.
- Require explicit approval for consequential external writes.

## Decision rights

- The user owns goals, scope, legal/business choices, and consequential external actions.
- AI tools may research, analyze, draft, organize, validate, and make reversible repository changes within granted permissions.
- Material adverse facts, conflicts, and high-impact assumptions must be surfaced.


## Bound document: CONNECTOR_PLAN.md

# Connector Plan

| Capability/source | Purpose | Boundary |
|---|---|---|
| Local workspace | Project state, copied firmware and evidence | Preparation now; reversible engineering only after ACTIVE |
| Named Downloads bundle | Source, checksum, handoff and script | Read/copy only; originals remain unchanged |
| Installed core/CLI | Exact implementation and compilation | Read-only inspection; after activation, compile outputs/cache remain in workspace; no upgrade/hardware authority implied |
| Web and official upstream GitHub | Espressif, Microsoft, USB-IF, Bluetooth SIG primary sources | Read-only; record exact URLs, versions and sections |
| Project GitHub publication | Future issue/PR/remote history | Disabled until correct ESP32 target and writes are authorized; template origin is not a target |
| Serial/Windows Bluetooth | Future operator observations | No active hardware grant; identify target and authorize run before opening serial, flashing, pairing, changing bonds/cache or sending input |

Do not run pre-existing `scripts/Invoke-BleAutoPair.ps1` as setup. No messaging, credentials, provider installation or persistent permission change is included. Tool availability is not authority.


## Bound document: SKILL_PLAN.md

# Skill Plan

| Skill/procedure | Purpose | Status |
|---|---|---|
| `.agents/skills/complex-project-bootstrapper/SKILL.md` | Preserve inputs and prepare a fingerprint-bound inactive foundation | Applied |
| Software-hardware profile, packets and execution harness | Separate machine checks from operator hardware evidence; bound future execution | Retained; engineering awaits activation |
| Repository read-only researcher/reviewer roles | Independently verify intake and review the proposal | Used during bootstrap; no execution worker dispatched |

No new skills or providers were installed; native skill copies are unchanged. Parser and log workflows will use normal project tools. Create a custom skill only if actual repetition later warrants it.


## Bound document: DOMAIN_PROFILE.md

# Domain Profile — Software + Hardware: ESP32-S3 BLE HID

This project specializes [the canonical software-hardware profile](templates/software-hardware/PROFILE.md). Its packet structure, verification ladder and independent acceptance rules apply. Project permissions and resource defaults below supersede generic local-model/GitHub workflow defaults; template examples do not authorize remote or physical actions.

## Fixed foundation

Keep immutable v7 evidence and experiment only in copied sketches. Pin esp32:esp32:esp32s3, Arduino-ESP32 3.3.12, built-in NimBLE and serial 921600. Preserve quiet boot, scanner command behavior, manufacturer-characteristic creation workaround, separate keyboard report 1/mouse report 2, and Report Reference semantics. Never prepend report IDs to GATT values, use clearDuplicateCache(), reintroduce Bluedroid-only APIs, or send Ctrl/Shift/Alt/GUI tests while notification stability is unresolved.

## Ordered investigation

1. Parse the existing descriptor byte-for-byte and retain offsets, collections, IDs and report lengths.
2. Inspect exact-core input-report/Report Reference construction and notify properties; verify Protocol Mode, HID Information, Report Map, Control Point and both inputs.
3. Read primary Windows HOGP/composite requirements before proposing any report-map change.
4. Prepare subscription, connection and security logging without input; compile the isolated sketch and retain recipe and exact ELF.
5. In an operator-authorized run, observe each subscription. Only after fresh mouse_sub=yes, run mouse-only t and verify no reset/stuck modifier and scanner return. Stop on reset, retain checkpoints and decode against the exact ELF.

## Components and evidence

Separate descriptor/protocol, GATT/device integration, telemetry, host transport and hardware operations into bounded scopes. Execution workers require canonical packets and the harness. Bootstrap orientation/review is not firmware execution. Machine checks progress through static, unit, contract, simulation and integration as applicable; hardware-in-loop/field results require operator records bound to exact task/build/device/timestamps/artifacts. Compilation does not earn hardware status. Hardware adapter/integration packets are high risk, requiring independent eligible cross-family acceptance review; no automatic waiver.

## Project-specific authority and defaults

No autonomous engineering before exact approval and ACTIVE validation. Then local research, copied-sketch changes, tests and workspace-contained builds may proceed. Use currently available session resources; install no local/cloud provider or model. GitHub project issues/PRs/publication remain disabled until the proper ESP32 target and actions are authorized, even where the generic profile lists these as routine.

The owner identifies board/unit/COM and Windows build and authorizes a concrete hardware session before serial, flash/erase, pairing/bond/cache changes or input. Those details do not block local descriptor research but are prerequisites for physical tests. Material changes to core/backend, board family, security, public report/command contracts or architecture return to the user for review. Baseline immutability cannot be waived by a worker.

