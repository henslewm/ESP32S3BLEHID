# BLE pairing repair and local telemetry comparison

This work changes Windows-side tooling only. The locked baseline, working sketch, serial commands and BLE security model remain unchanged. Fresh hardware pairing and `mouse_sub=yes` have **not** been established by code or unit tests.

## Implementation and outcomes

`scripts/Invoke-BleAutoPair.ps1` runs locally on WINSTONDESKTOP in interactive Windows PowerShell 5.1. Supply the address observed from serial `i`; `DeviceName` is a diagnostic label and never a selector. Accepted address forms are twelve hex digits or six consistently colon/hyphen-separated pairs. An address alone defaults to pairing. No arguments prints usage without native calls. `-DiscoverOnly` cannot be combined with mutation switches; without an address it lists available AEP records without changing state.

With an address, discovery opens the device directly: `BluetoothLEDevice.FromBluetoothAddressAsync` (exact 48-bit address), then `DeviceInformation.CreateFromIdAsync(..., AssociationEndpoint)` for the address, paired state, presence and LE connectability properties. On 2026-09-27 this returned in about 50 ms, where the earlier `FindAllAsync` query over unpaired LE endpoints never completed within 30 seconds. `FindAllAsync` is still used for `-DiscoverOnly` without an address. No name match is used; duplicate exact-address endpoints are refused. Each wait is bounded to 30 seconds. Missing optional properties are recorded as null.

Pairing uses custom `ConfirmOnly` pairing. Plain `PairAsync()` returned `Failed` within 40 ms from this desktop process, which has no pairing UI. `scripts/BleCustomPairing.cs` accepts the Just Works confirmation in-process, because a PowerShell scriptblock cannot answer the WinRT event synchronously. It returns the native operation to the same bounded wait, cancellation and postcheck logic. The module compiles it once into ignored `build/pairing/` with the .NET Framework `csc.exe`, which requires the Windows SDK `UnionMetadata\<version>\Windows.winmd`. Unpairing uses `UnpairAsync()` and verifies Windows state before any requested re-pair. It does not prove the peripheral erased its stored bonds. The observed unpair-then-pair still succeeded without clearing the ESP32 bond store, and no repeat-pairing event was logged. Hardware result: [evidence](../evidence/mouse-fix-2026-09-27.md).

Every native mutation waits at most 120 seconds. On timeout, the script requests cancellation through `IAsyncInfo`, refreshes the exact-device state, and checks for a terminal result. Pending, conflicting or unobservable outcomes return unknown without retries. A terminal late success can pass only with exact-device confirmation. `endedUtc`/`elapsedMs` describe the bounded wait; `terminalObservedUtc` records observation of terminal completion, including reconciliation. Already-paired targets still receive a fresh postcheck.

| Exit | Meaning |
|---|---|
| 0 | Verified requested Windows state, successful discovery, or usage guidance |
| 1 | Definite failure, with available native result and state evidence |
| 2 | Invalid input/runtime or evidence-output failure |
| 3 | Unknown outcome; inspect evidence and reconcile before another attempt |

`-ResultPath` writes structured JSON to a fresh path and refuses overwrite. Results include script/module SHA-256, native statuses, exceptions/HRESULTs, UTC timestamps, elapsed time, cancellation and refreshed state. JSON is also printed to the console. An unwritable output destination can still fail after mutation; retain console evidence and do not infer that exit 2 means pairing did not happen.

## First operator run

Use a local Windows PowerShell 5.1 terminal (`powershell.exe`), with the ESP32 under the operator's control. No remote execution is supported. Confirm its **Own BLE address** using serial `i`, enter advertising using `b`, then assign the observed value below. Do not reuse an address from an old script.

```powershell
$address = Read-Host 'Exact Own BLE address from serial i'
.\scripts\Invoke-BleAutoPair.ps1 -BleAddress $address -DiscoverOnly
```

Review the address, name, AEP identity, paired state, presence and connectability. If the target is absent or ambiguous, stop and retain the result. Run the two recorded attempts separately:

```powershell
# SetupUnpair is an explicit Windows unpair before measurement; omit if already unpaired.
.\scripts\Invoke-BlePairingJournal.ps1 -Mode Scripted -BleAddress $address -SetupUnpair
.\scripts\Invoke-BlePairingJournal.ps1 -Mode Manual -BleAddress $address -SetupUnpair
```

For the manual attempt, the script prompts for a start marker immediately before the Settings action and an outcome/completion marker afterward. Keep the operator's Settings action within that interval. Windows Settings may reuse an existing process. If the user cannot distinguish the intended device in Settings, stop rather than selecting by a duplicate name.

Each journal requires a freshly discovered, unpaired exact target before measurement. Setup API evidence is retained separately and excluded from capture. The observer becomes ready before a fresh scripted subject process launches. The collector continues for ten seconds after completion; manual postcheck discovery occurs after capture. A scripted subject exceeding the journal's 210-second envelope is left running with an unknown outcome, not killed or retried. The collector has a 20-minute ceiling and reports incomplete coverage if exceeded.

Inspect serial `q` after pairing and retain its actual output separately with the run identity. `connected=yes`, `keyboard_sub=yes`, and **`mouse_sub=yes`** remain required. The scripts issue no serial commands and never send `t`. Any subsequent mouse diagnostic requires fresh `mouse_sub=yes` and the applicable operator authority. Successful Windows pairing alone does not establish mouse subscription or complete the HID milestone.

If native pairing still returns `Failed`, retain the run and leave the pairing milestone unresolved.

## Journal evidence and comparison

Unique directories under ignored `build/pairing-runs/` contain `run.json`, raw `events.jsonl`, and `summary.json`, plus coverage, setup results, scripted stdout/stderr and API result, or manual markers/postcheck. Interrupted/setup-failed runs preserve partial artifacts and an inconclusive summary. Treat local event content as private; do not automatically publish it.

Metadata records host/build/session, target identity, UTC bounds, hashes of each participating script/module, process roles/lifetimes and executable SHA-256 separately. `summary.json` maps captured measured events to observer/subject/unattributed roles; setup is explicitly recorded outside that window. Sysmon uses EventData ProcessId and ProcessGuid with creation-time and image confirmation, never the provider's System execution PID. Unresolved lifetimes remain inconclusive. 4104 records are reassembled by source process, role and ScriptBlockId; missing or conflicting fragments are flagged. A script block does not prove each contained statement executed.

The collector inventories PowerShell, Sysmon and locally available Bluetooth/BTH/UserPnp channels plus applicable System device providers. It records missing, disabled, denied and unsupported analytic/debug channels, query errors, clear/rollover signals, query caps and unread tail records. It changes no logging policies, services or Wazuh configuration. Polling cannot promise lossless capture; event gaps prevent an absence conclusion. Events without a structured address/AEP/device-instance link remain temporal candidates.

```powershell
.\scripts\Invoke-BlePairingJournal.ps1 -Mode Compare `
  -ScriptedRun 'build\pairing-runs\<scripted-run-id>' `
  -ManualRun 'build\pairing-runs\<manual-run-id>'
```

Comparison emits a Markdown table with `observed`, `not observed in the captured window`, or `unavailable/inconclusive`, counts and limitations. There is no numerical detection score. On 2026-09-27, read-only preflight on WINSTONDESKTOP found the Sysmon channel missing and WazuhSvc stopped. Each run rechecks these facts. Local event capture establishes neither Wazuh ingestion nor alerts.

## Verification

```powershell
powershell.exe -NoProfile -File .\scripts\Test-BlePairing.ps1
```

Tests use installed Pester 3.4.0 and mocked BLE wrappers. One real WinRT test reads an existing local file to verify async projection/cancellation; it never calls Bluetooth. Test reports and collector smoke data live under ignored `build/pairing-development/`. These checks are software evidence, not operator or cross-family hardware acceptance.

## Primary contracts

- [Microsoft enumeration/pairing sample](https://learn.microsoft.com/en-us/samples/microsoft/windows-universal-samples/deviceenumerationandpairing/): pairing requires AEP; Windows owns basic-pairing UI.
- [FindAllAsync](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformation.findallasync), [device properties](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/device-information-properties), [PairAsync](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformationpairing.pairasync), [UnpairAsync](https://learn.microsoft.com/en-us/uwp/api/windows.devices.enumeration.deviceinformationpairing.unpairasync?view=winrt-26100), [IAsyncInfo.Cancel](https://learn.microsoft.com/en-us/uwp/api/windows.foundation.iasyncinfo.cancel).
- [PowerShell 5.1 logging](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging?view=powershell-5.1), [4104 fragmentation](https://devblogs.microsoft.com/powershell/powershell-the-blue-team/), [Get-WinEvent](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-5.1).
- [Sysmon](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon), [event System execution schema](https://learn.microsoft.com/en-us/windows/win32/wes/eventschema-execution-systempropertiestype-element), [event-log errors](https://learn.microsoft.com/en-us/windows/win32/wes/windows-event-log-error-constants), [Wazuh collection](https://documentation.wazuh.com/current/user-manual/capabilities/log-data-collection/configuration.html).
