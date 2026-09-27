# Firmware module index

Read this file first, then open only the module that owns what you are changing. Each header (`.h`) is the module's contract; the `.cpp` is its implementation. Arduino compiles every `.cpp` in this folder together with `BLEScanner_WORKING_v7.ino`.

Build: `pio run -e dev` (root `platformio.ini`, rules in `docs/PLATFORMIO.md`). Equivalent arduino-cli: `arduino-cli compile -b esp32:esp32:esp32s3:CDCOnBoot=cdc,PSRAM=opi,FlashMode=qio,FlashSize=16M --build-property build.partitions=default_16MB --build-property upload.maximum_size=6553600 firmware/BLEScanner_WORKING_v7`.

| Module | Owns | Public API | Depends on |
|---|---|---|---|
| `BLEScanner_WORKING_v7.ino` | `setup()`, `loop()` | — | all below |
| `config.h` | BLE includes, backend/board checks, compile-time constants (baud, scan timing, queue sizes) | constants | — |
| `scan_types.h` | `PacketSnapshot`, `DeviceStats` records | types | config |
| `ble_format.*` | Pure formatting: addresses, hex, UUID/company names, adv types | `printAddress`, `printHex`, `le16`, `fnv1a32`, `uuid16Name`, `companyName`, `advTypeName`, … | — |
| `ad_decoder.*` | Advertising-data decoding (iBeacon, Eddystone, flags), identity extraction | `decodeAD`, `extractIdentity` | ble_format |
| `packet_queue.*` | Callback-to-loop ring buffer | `enqueuePacket`, `dequeuePacket`, `clearPacketQueue`, `g_queueDrops` | — |
| `device_stats.*` | Per-device stats, packet display, summary report | `processPacket`, `printSummary`, `clearResearchStats`, `g_stats` | ble_format, ad_decoder, packet_queue, scanner, hid_mode |
| `scanner.*` | Scan runtime options, NimBLE scan callbacks, finite slices, presets | `startScanSlice`, `stopScanner`, `resumeScanner`, `restartScanner`, `startPreset`, `g_scan`, runtime flags | packet_queue, hid_mode |
| `hid_report_map.*` | HID report descriptor bytes (keyboard ID 1, mouse ID 2) | `HID_REPORT_MAP`, `HID_REPORT_MAP_LEN` | — |
| `hid_core_workaround.*` | Registers a second 0x2A4D input report that core 3.3.12 would silently drop | `hidAddInputReport` | — |
| `hid_mode.*` | HID GATT build, connection/subscription tracking, start/stop (stop disconnects the host), mouse-only `t` test | `startHidMode`, `stopHidMode`, `sendHidTestInjection`, `g_hidMode`, `g_hidConnected`, `g_keyboardSubscribed`, `g_mouseSubscribed` | hid_report_map, hid_core_workaround, hid_diag, scanner |
| `hid_diag.*` | Observation only: build ID, report handles, raw NimBLE GAP events (connect, encryption, every subscribe) | `FIRMWARE_BUILD_ID`, `printBuildIdentity`, `hidDiagBegin` | — |
| `commands.*` | Serial command contract (`h 1-4 p s i m v r d a u k x + - b B t q`) | `handleCommand` | scanner, device_stats, hid_mode, hid_diag |

State shared through `extern` globals is written only by its owning module; the other modules read it.

## Change rules

- Put a new capability in a new module or in the module that owns that state; don't grow the `.ino`.
- Keep each module's header the complete description of how other modules may use it.
- `FIRMWARE_BUILD_ID` is injected at build time (`scripts/pio_build_id.py` for PlatformIO; `$id = python scripts/pio_build_id.py --sketch firmware/BLEScanner_WORKING_v7 --toolchain cli` then `--build-property "compiler.cpp.extra_flags='-DFIRMWARE_BUILD_ID=\"$id\"'"` for arduino-cli (see `docs/PLATFORMIO.md`)). An unlabeled build prints `unlabeled`. Record the ELF hash of every flashed build in evidence.
- Serial command meanings in `commands.cpp` are a fixed interface (see `PROJECT_CHARTER.md`).
