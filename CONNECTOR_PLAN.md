# Connector Plan

| Capability/source | Purpose | Boundary |
|---|---|---|
| Local workspace | Project state, copied firmware and evidence | Preparation now; reversible engineering only after ACTIVE |
| Named Downloads bundle | Source, checksum, handoff and script | Read/copy only; originals remain unchanged |
| Installed core/CLI | Exact implementation and compilation | Read-only inspection; after activation, compile outputs/cache remain in workspace; no upgrade/hardware authority implied |
| Web and official upstream GitHub | Espressif, Microsoft, USB-IF, Bluetooth SIG primary sources | Read-only; record exact URLs, versions and sections |
| Project GitHub publication | Future issue/PR/remote history | Disabled until correct ESP32 target and writes are authorized; template origin is not a target |
| Serial/Windows Bluetooth | Future operator observations | No active hardware grant; identify target and authorize run before opening serial, flashing, pairing, changing bonds/cache or sending input |

Do not run pre-existing `scripts/Invoke-BleAutoPair.ps1` as setup. No messaging, credentials, provider installation or persistent permission change is included. Tool availability is not authority.
