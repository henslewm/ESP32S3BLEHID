# Operator-supplied serial observation — i, b, B

Source: user pasted this serial-monitor output on 2026-09-27 while continuing local WINSTONDESKTOP pairing. Original capture time, COM port and exact flashed artifact/ELF were not supplied. This is operator-provided evidence, not an agent serial capture.

```text
SYSTEM INFO
BLE stack: NimBLE
Own BLE address: 7c:4f:ad:21:52:89 (type 99)
CPU: 240 MHz
Flash: 16777216 bytes
Free heap: 166424 bytes
PSRAM: 8388608 bytes
NimBLE BLE5 feature support: yes
Low-level NimBLE EXT_SCAN: not enabled
HID mode: off connected=no keyboard_sub=no mouse_sub=no

[HID] advertising=yes

[HID] Mode STARTED. Advertising as S3-HID-KM-v7 (Generic HID keyboard + mouse).
[HID] Pairing: Just Works (no PIN). Bonding enabled.
[HID] GAP appearance=0x03C0 Generic HID; PnP vendor source=Bluetooth SIG, vendor=0x02E5.
[HID] The scanner is paused. Use 1-4 to resume scanning,
[HID] or B to stop HID mode.
[HID] After the target pairs and connects, press t to
[HID] run the mouse-only notification diagnostic.

[HID] Mode STOPPED. HID advertising halted.
[HID] The scanner remains paused; use 1-4 to scan again.
```

The user explicitly described running `i`, lowercase `b`, then uppercase `B`. The confirmed target address is `7C:4F:AD:21:52:89`; the last reported state is advertising stopped. Advertising must be restarted with lowercase `b` and left enabled before the intended discovery/pairing run. The initial unconnected/subscription values preceded advertising and do not establish the later pairing state.

The printed `t` suggestion is preserved as source text only. The project gate still requires freshly observed `mouse_sub=yes` before any operator-authorized mouse diagnostic. No `t` was requested or sent.

Latest user steering: ignore Wazuh and the VM lab for now; focus on local pairing. No fresh exact-device pairing success is established by this transcript.

The operator subsequently replied `ok` to restarting lowercase b and leaving it advertising for discovery.

Read-only source inspection found that the locked/working sketch's `printSystemInfo()` (around lines 3569-3609) does not print Own BLE address or a type-99 value; its BLE stack line is followed directly by CPU. The serial text includes instrumentation absent from this checked-in source. The meaning of `type 99` and exact running firmware remain unknown; this is not evidence of a bad BLE address type. The source's b/B start/stop behavior matches the transcript.
