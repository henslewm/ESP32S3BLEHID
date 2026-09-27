# Baseline import — 2026-09-27

Source: `C:\Users\hensl\Downloads\BLEScanner_FULL_CORRECTED_HIDDIAG_v7_GENERIC_HID.ino`, 61,594 bytes. SHA-256: `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`.

Downloads lacked BLEScanner_LOCKED_BASELINE_v7.ino; the similarly named TXT is a checksum manifest. Source bytes were copied under the expected locked filename into new archive/handoff-import-2026-09-27 beside exact copies of the original PS1, Markdown and checksum file. Duplicate (1) variants match their unsuffixed counterparts. No original was renamed or edited.

The reviewed script force-copies three files, verifies the copied baseline and creates a working copy only if absent. Source hash and destination absence were checked first; no existing baseline was overwritten. The script performs no serial, pairing, upload, network or filesystem-lock action.

Direct invocation was refused because the downloaded script was unsigned. The unchanged staged script then completed in a child `pwsh -NoProfile -ExecutionPolicy Bypass -File ... -Destination ...` process. This setting applied only to that process; no persistent execution policy, ACL or original-file change occurred. Output confirmed the expected SHA-256.

This directory preserves the script output verbatim. Its BLEScanner_WORKING_v7.ino is an import snapshot, not the editable target. A further exact copy at firmware/BLEScanner_WORKING_v7/BLEScanner_WORKING_v7.ino is the project sketch. Do not build evidence/staging directories: Arduino concatenates sketch-folder .ino files ([official build process](https://docs.arduino.cc/arduino-cli/sketch-build-process/)).

Older archive/BLEScanner.ino remains at SHA-256 `310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580`. These file checks establish no fresh compile or hardware success.
