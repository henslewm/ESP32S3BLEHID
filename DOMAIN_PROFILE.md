# Domain Profile — Software + Hardware: ESP32-S3 BLE HID

This project specializes [the canonical software-hardware profile](templates/software-hardware/PROFILE.md). Its packet structure, verification ladder and independent acceptance rules apply. Project permissions and resource defaults below supersede generic local-model/GitHub workflow defaults; template examples do not authorize remote or physical actions.

## Fixed foundation

Keep immutable v7 evidence and experiment only in copied sketches. Pin esp32:esp32:esp32s3, Arduino-ESP32 3.3.12, built-in NimBLE and serial 921600. Preserve quiet boot, scanner command behavior, manufacturer-characteristic creation workaround, separate keyboard report 1/mouse report 2, and Report Reference semantics. Never prepend report IDs to GATT values, use clearDuplicateCache(), reintroduce Bluedroid-only APIs, or send keyboard or mouse input except under the charter's phase 2 rails (explicit host command, bounded, release-all on every stop path).

## Build configuration

Keep a root `platformio.ini` generated under [docs/PLATFORMIO.md](docs/PLATFORMIO.md): observed hardware, a pinned platform matching Arduino-ESP32 3.3.12 (pioarduino `55.03.312-1`), hardware-ID ports and a quiet default log level. arduino-cli with the documented equivalent FQBN remains a supported build path. Evidence names the toolchain and ELF hash of every flashed build. Firmware code follows the modular rule in `PROJECT_CHARTER.md` and `firmware/BLEScanner_WORKING_v7/MODULES.md`.

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
