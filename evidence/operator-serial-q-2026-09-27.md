# Operator mouse-subscription observation — 2026-09-27

Source: user-pasted serial output after the user confirmed that Windows Settings listed `S3-HID-KM-v7` and was asked to select that device once. The user explicitly stated that `q` was sent twice.

```text
/
[HID] Central CONNECTED. Pairing/bonding in progress.
[HID] Watch the Win11 target now: Defender history,
[HID] Sysmon events, and the Bluetooth devices list.
[HID] keyboard notifications: SUBSCRIBED
[HID] mode=yes connected=yes keyboard_sub=yes mouse_sub=no
[HID] mode=yes connected=yes keyboard_sub=yes mouse_sub=no
```

Both observations show a connection and a keyboard subscription, with no mouse subscription reported. The exact flashed artifact, serial capture time and Windows final pairing status were not independently established. This is not evidence of successful scripted pairing or completed HID acceptance. No agent sent serial commands or HID input.

The earlier address/start/stop observation is in [operator-serial-i-b-B-2026-09-27.md](operator-serial-i-b-B-2026-09-27.md). The checked-in source lacks some instrumentation printed by the running firmware; preserve that uncertainty when correlating code with this observation.
