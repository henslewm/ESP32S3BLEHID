# Modular Code

- Before firmware work, read `firmware/BLEScanner_WORKING_v7/MODULES.md` and open only the modules that own the state you are changing. Don't read the whole sketch folder by default.
- Treat each module's header as its contract; change the header only when the contract changes.
- Add new behavior to its owning module or a new module; keep `BLEScanner_WORKING_v7.ino` to `setup()`/`loop()`.
- Update `MODULES.md` in the same change whenever a module, public function or ownership changes.
- Never hard-code `FIRMWARE_BUILD_ID`: builds inject it from git SHA, toolchain and environment (`scripts/pio_build_id.py`, or `-DFIRMWARE_BUILD_ID=` for arduino-cli). Record the ELF hash of every flashed build in evidence.
