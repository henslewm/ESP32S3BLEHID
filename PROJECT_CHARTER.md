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

Phase 1 (done 2026-09-27): determine and resolve why Windows subscribes to keyboard report ID 1 but not mouse report ID 2 while preserving the locked v7 baseline, quiet boot, and working interactive BLE scanner.

Phase 2 (approved by charter revision ESP-ADR-020): use the board as a BLE keyboard and mouse that the owner drives from their own PC to automate their own work. Input is sent only on explicit host commands, with safety rails that make stuck keys and unattended input impossible by design.

## Definition of done

- Locked baseline SHA-256 remains 9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6.
- Board boots quietly to READY HIDDIAG-v7. h=help; b enters HID mode without reset; Windows sees S3-HID-KM-v7 and connects without reset.
- q reports connected=yes, keyboard_sub=yes, and mouse_sub=yes in a recorded hardware run.
- Only after mouse_sub=yes, t produces mouse movement only, with no stuck keyboard modifiers and no ESP32 reset.
- Returning to scan mode still works; original interactive scanner commands remain available.
- Evidence distinguishes source checks, compilation, and operator-observed hardware results; any backtrace is decoded against the exact run's ELF.

### Phase 2 definition of done

- A host-command protocol on the USB serial link types text, sends key chords (including Ctrl/Shift/Alt/GUI), and moves, clicks and scrolls the mouse. Commands are framed lines that cannot be confused with the existing single-character commands, and every existing command keeps its meaning.
- Release-all (neutral keyboard and mouse reports) is sent after every chord, on a stop command, on leaving HID mode, on host disconnect, on an idle timeout and on any protocol error. Each case is observed on hardware with no stuck key or button.
- A host-side PowerShell helper sends commands and reports each command's acknowledgement or error. Protocol tests run without hardware.
- Operator-observed runs on the owner's PC show typed text, a modifier chord and mouse actions landing correctly, with no reset.

## Required deliverables

- Hash-verified preserved handoff and baseline with provenance; isolated editable Arduino sketch.
- Byte-for-byte HID descriptor parser output and Arduino-ESP32 3.3.12 input-report/GATT implementation audit.
- Primary-source Windows HOGP findings and a small diagnostic experiment logging subscriptions and security without sending HID input.
- Bounded fixes, compile records, exact ELF/build metadata, operator hardware evidence, and current repository handoff.

## Scope

### In scope

- Work necessary to achieve the desired outcome and deliverables.

### Out of scope

- Unrelated devices, scanner redesign, and declaring HID complete without every hardware acceptance observation.
- Autonomous or stored input: no input at boot, no on-device scripts or timers that send input, and no input without a live host command.
- Use against machines the owner does not own or control, and any credential capture or security-bypass use.
- Changing BLE backend, framework, board family, security model, or public command/report interface without renewed architecture approval.
- Continuing the inherited universal-ai-project-template issue sequence or publishing to its remote.
- FE1.1s USB hub integration or any USB-hub hardware path; this project is BLE HID only.

## Constraints and approval gates

- Never modify or overwrite the locked baseline or Downloads originals. Experiments belong in firmware/BLEScanner_WORKING_v7 or a separate experiment copy.
- Preserve scanner functionality, all existing command meanings, and quiet boot.
- Pin Arduino-ESP32 3.3.12, built-in NimBLE, and esp32:esp32:esp32s3; do not reintroduce Bluedroid-only APIs or call BLEScan::clearDuplicateCache().
- Create BLEHIDDevice manufacturer characteristic with manufacturer() before setting its value; never prepend report IDs to GATT input values.
- `t` stays the mouse-only diagnostic and never runs before mouse_sub=yes.
- Keyboard and mouse input (phase 2) is sent only in response to explicit host commands and only while connected and subscribed to the target report. It must be bounded: a maximum text length per command, a per-report rate limit, and release-all after every chord and on each trigger listed in the phase 2 definition of done. Modifier chords are enabled only after release-all has been observed on hardware. New commands are additive and must not change the existing command meanings.
- Before changing report map bytes, parse the existing descriptor and inspect the exact 3.3.12 implementation and primary Windows HOGP expectations.
- Use small testable changes and retain each result; a successful build is not hardware verification.
- Keep code modular so a model can work on one part without re-reading the whole codebase. Firmware lives in single-responsibility modules listed in `firmware/BLEScanner_WORKING_v7/MODULES.md`, each with a header that is its contract. New behavior goes in its owning module or a new one, never back into a monolithic sketch, and the index is updated in the same change. Scripts follow the same rule: one focused module or helper per concern.
- No hardware operation, Windows pairing/cache changes, flash/erase, Git publication, communications, credential access, permissions changes, or toolchain migration without the applicable explicit authority.
- Preserve pre-existing archive/BLEScanner.ino and untracked scripts/Invoke-BleAutoPair.ps1; their presence does not authorize execution.

- Preserve authoritative source material and provenance.
- Keep secrets and unapproved restricted material out of Git.
- Require explicit approval for consequential external writes.

## Decision rights

- The user owns goals, scope, legal/business choices, and consequential external actions.
- AI tools may research, analyze, draft, organize, validate, and make reversible repository changes within granted permissions.
- Material adverse facts, conflicts, and high-impact assumptions must be surfaced.
