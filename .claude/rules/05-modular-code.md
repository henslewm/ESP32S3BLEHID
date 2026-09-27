# Modular Code

- Before firmware work, read `firmware/BLEScanner_WORKING_v7/MODULES.md` and open only the modules that own the state you are changing. Don't read the whole sketch folder by default.
- Treat each module's header as its contract; change the header only when the contract changes.
- Add new behavior to its owning module or a new module; keep `BLEScanner_WORKING_v7.ino` to `setup()`/`loop()`.
- Update `MODULES.md` in the same change whenever a module, public function or ownership changes.
- Bind hardware evidence to the runtime `elf_sha256` the firmware prints (the embedded ELF hash), and record the ELF hash of every flashed build. `FIRMWARE_BUILD_ID` is an injected label (`scripts/pio_build_id.py`); never hard-code it.
