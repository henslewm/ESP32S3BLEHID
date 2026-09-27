# HID reference review — 2026-09-27

The user supplied a survey of combo HID libraries and lab tooling as context. This review used public primary sources only. It made no local code changes, shell/device calls, dependency installations or architecture changes. The pasted examples and lab checklist are contextual suggestions, not newly approved project requirements.

## Findings relevant to the mouse issue

| Reference | Verified finding | Relevance and limit |
|---|---|---|
| [TheNitek combo keyboard implementation](https://github.com/TheNitek/ESP32-NimBLE-Combo/blob/master/BleComboKeyboard.cpp) | One HID object creates keyboard, media and mouse input reports; the report IDs are also used in the report map. | Useful construction pattern. The source uses older APIs; compatibility with this project's exact core/backend was not tested. |
| [NimBLE maintainer discussion #1024](https://github.com/h2zero/NimBLE-Arduino/discussions/1024) | On 2025-09-04 the maintainer said the combo library needed updating. The linked fork in that discussion is A-box1000/ESP32-NimBLE-Combo. | This does not establish compatibility or maintenance status for every fork. Do not label TheNitek's fork a verified current replacement. |
| [Hijel keyboard source](https://github.com/HijelHub/HijelHID_BLEKeyboard/blob/main/src/HijelHID_BLEKeyboard.cpp) and [mouse source](https://github.com/HijelHub/HijelHID_BLEMouse/blob/main/src/HijelHID_BLEMouse.cpp) | Each initializes/configures BLE, installs server callbacks, creates a HID object, sets its report map and configures advertising. | Calling both independent begin methods is not an established combined-device integration. These external NimBLE-Arduino implementations are references, not drop-in replacements for the approved built-in backend. |
| [Hijel keyboard requirements/API](https://github.com/HijelHub/HijelHID_BLEKeyboard) | The published requirements name Arduino-ESP32 3.x and NimBLE-Arduino >=2.3.8. The documented special-key API is tap(KEY_RETURN); write handles characters. | The supplied combined sketch is approximate, not a verified program. Version/API checks would precede any separately approved experiment. |
| [Bit Pirate v1.6 release](https://github.com/geo-tp/ESP32-Bit-Pirate/releases/tag/v1.6) | The Bluetooth mouse entry records corrections to BLE HID mouse and keyboard report definitions. | A relevant change to inspect. The correction is in v1.6, not v1.7. No byte comparison or proof of the same defect in this firmware was performed. |
| [HIDForge README](https://github.com/Meshwa428/HIDForge) | Its advertised composite-device feature describes USB HID plus mass storage. | That claim alone does not establish combined BLE keyboard/mouse support. |
| [Espressif esp_hid_device example](https://github.com/espressif/esp-idf/tree/master/examples/bluetooth/esp_hid_device) | Includes BLE/NimBLE paths and lists ESP32-S3 as supported. | A reference for HID construction and events; migration to ESP-IDF is not part of the current work. |
| [Espressif Classic HID API](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/bluetooth/esp_hidd.html) and [Classic API index](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/bluetooth/classic_bt.html) | The esp_bt_hid_device_virtual_cable_unplug API belongs to the Bluetooth Classic HID path. | Do not apply that API to the current BLE/NimBLE implementation. |

Sources were read on 2026-09-27. Branch URLs and stable documentation can change; this review did not pin every upstream commit or compile these libraries. The source observations above are research evidence, not host/device validation.

## Implication for the existing investigation

The operator reported connected=yes, keyboard_sub=yes, mouse_sub=no twice. Comparing the combined report map, mouse report ID/reference and notification characteristic is a focused investigative lead. The observation does not by itself prove a descriptor defect, successful bonding, or the cause of the Windows scripted enumeration timeout.

Keep the two unresolved results distinct:

- Mouse subscription: operator-observed failure after a manual Settings action.
- Scripted pairing: no agent PairAsync/UnpairAsync was reached because exact AEP discovery did not complete.

No replacement firmware, automatic input examples, bond-clearing routine, Wazuh/VM work or new lab requirement was adopted from the supplied survey.
