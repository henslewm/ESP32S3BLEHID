# Arduino-ESP32 3.3.12 core excerpts

Verbatim excerpts from the installed Arduino-ESP32 3.3.12 core, `libraries/BLE/src/` (Apache-2.0). Kept so a reviewer can compare the workaround in `firmware/BLEScanner_WORKING_v7/hid_core_workaround.cpp` with the core code it mirrors.

| Excerpt | Source file | Lines | Full-file SHA-256 | File lines |
|---|---|---|---|---|
| `BLEHIDDevice.cpp.162-193.txt` (`inputReport()`) | `BLEHIDDevice.cpp` | 162-193 | 7b0486e97d41d531323e11d401f12df497a44287148ff52316aab1a3aa4e30d9 | 345 |
| `BLEService.cpp.252-282.txt` (`addCharacteristic()` duplicate-UUID drop) | `BLEService.cpp` | 252-282 | 2b71699e1962cdc37a54ace429ebdd408b0e40b379d621d427add5bb5a93b252 | 672 |

Regenerate by slicing those line ranges from the installed core.
