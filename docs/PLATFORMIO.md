# PlatformIO configuration rules (Arduino / ESP32)

Every Arduino or ESP32 firmware project keeps a root `platformio.ini` next to its Arduino IDE/CLI instructions. Generate it from observed hardware and the project's pinned toolchain, never from a copied example. These rules are the same in the universal AI project template (software-hardware profile).

## Generation rules

1. **Identify the hardware first.** Run `esptool --port <port> flash-id` (read-only; it resets the board) and record the chip, revision, flash size and embedded PSRAM line as a comment at the top of the ini. Never assume PSRAM or flash size from a board name.
2. **Match the platform to the pinned Arduino core.**
   - Arduino-ESP32 **2.0.x**: `platform = espressif32@<exact 6.x>`.
   - Arduino-ESP32 **3.x**: stock `espressif32` does not ship 3.x. Use a pinned pioarduino release URL, for example `https://github.com/pioarduino/platform-espressif32/releases/download/55.03.312-1/platform-espressif32.zip` (tag `55.03.312-1` = Arduino v3.3.12 / ESP-IDF v5.5.5).
   - Never use `latest`, a branch, or a floating range for a pinned core.
   - Look up the tag with `gh api repos/pioarduino/platform-espressif32/releases`; release names state the Arduino version.
3. **Memory from the observed chip.**
   - `board_build.arduino.memory_type`: `qio_opi` for octal PSRAM (ESP32-S3 R8/R16 parts, esptool shows "Embedded PSRAM 8MB (AP_3v3)"); `qio_qspi` for quad or no PSRAM.
   - Add `-DBOARD_HAS_PSRAM` only when PSRAM exists.
   - Set `board_upload.flash_size` and `board_build.partitions` from the detected flash size. Set `board_upload.maximum_size` to the **application partition** size in that partition table (e.g. `app0` = `0x640000` = 6553600 in `default_16MB.csv`), never the physical flash size.
4. **Serial and ports.**
   - Set `-DARDUINO_USB_CDC_ON_BOOT=1` only when the console is the chip's native USB (ESP32-S3/C3 USB-Serial/JTAG, VID:PID `303A:1001`).
   - Select ports by hardware ID (`upload_port = hwgrep://303A:1001`), not COM numbers.
   - `monitor_speed` equals the sketch's `Serial.begin()` baud.
5. **Source layout.** If the sketch is not in `src/`, set `[platformio] src_dir` to the sketch folder. Exactly one `.ino` tree may be under `src_dir`; evidence or archived sketches must stay outside it.
6. **Environments.**
   - The default `dev` environment must respect the project's boot and log requirements. Use `CORE_DEBUG_LEVEL=1` when a quiet boot is required.
   - Put verbose logs (`=4`) in a separate `debug` environment.
   - `release` uses `=0`.
7. **Compiler flags.** Don't override the C++ standard unless the code needs it. Arduino-ESP32 3.x already uses `-std=gnu++2b`, so forcing `gnu++17` is a downgrade.
8. **Monitor.** Include `monitor_filters = esp32_exception_decoder, time` so crashes decode against the exact ELF.
9. **Ignore output.** Add `.pio/` to `.gitignore`.
10. **Keep builds equivalent.** Record the arduino-cli FQBN and `--build-property` values that produce the same configuration, and state which toolchain produced any flashed artifact. A PlatformIO ELF and an arduino-cli ELF are different artifacts.
11. **Generate the build identifier.** Don't hard-code it. Inject a firmware build ID from build metadata (git short SHA plus, when the tree is dirty, a hash of `git diff HEAD --binary` and every untracked non-ignored file, so any build-affecting change, including `lib/` and `include/`, gets its own ID; then toolchain and environment) through an `extra_scripts` pre-script, and through `--build-property compiler.cpp.extra_flags=-DFIRMWARE_BUILD_ID=...` for arduino-cli, so serial evidence binds to the exact artifact.
12. **Verify before relying on it.** `pio run -e <default>` must succeed. For hardware claims, upload, run the project's smoke test and record the build ID and ELF SHA-256. A successful compile is not hardware verification.

## This project

- Board: ESP32-S3 (QFN56) rev v0.2, 16 MB flash, embedded 8 MB octal PSRAM (esptool 5.3.1, 2026-09-27).
- `platformio.ini` builds `firmware/BLEScanner_WORKING_v7` with Arduino 3.3.12 via pioarduino `55.03.312-1`.
- Hardware-verified with build `v7-split-diag4-pio`: PSRAM 8 MB visible, both HID subscriptions, `t` PASS, scanner return. [Record](../evidence/mouse-fix-2026-09-27.md).
- Commands:
  - `pio run -e dev` builds.
  - `pio run -e dev -t upload` builds and uploads.
  - `pio device monitor` opens the serial monitor.
  - Close any monitor or `scripts/serial_bridge.py` before uploading.
- arduino-cli equivalent, PowerShell, with the same build ID: `$id = python scripts/pio_build_id.py cli; arduino-cli compile -b esp32:esp32:esp32s3:CDCOnBoot=cdc,PSRAM=opi,FlashMode=qio,FlashSize=16M --build-property build.partitions=default_16MB --build-property upload.maximum_size=6553600 --build-property "compiler.cpp.extra_flags='-DFIRMWARE_BUILD_ID=`"$id`"'" firmware/BLEScanner_WORKING_v7`. Verified 2026-09-27: the binary contains the generated ID. Earlier builds used plain `CDCOnBoot=cdc`, with PSRAM disabled and the default partitions.
