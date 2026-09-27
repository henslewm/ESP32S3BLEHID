# Local Windows discovery — 2026-09-27

Target: WINSTONDESKTOP, operator-reported ESP32 address `7C:4F:AD:21:52:89`. Operator supplied i/b/B output, then replied `ok` to restarting lowercase b and leaving advertising active. No agent serial command was sent. Wazuh and VM lab were excluded per user steering.

Original raw results remain in ignored `build/pairing-runs/local-20260927T105819Z-4484b0ec11f542adaa2eea4936b3223b/`. Six relevant files were copied unchanged into tracked [discovery-2026-09-27/](discovery-2026-09-27/); [manifest.json](discovery-2026-09-27/manifest.json) records original paths and verified SHA-256 values.

| Artifact | Result | Interpretation |
|---|---|---|
| discovery.json | FindAllAsync E_ACCESSDENIED 0x80070005 after 188 ms | Sandbox denied access; no pairing |
| discovery-desktop.json | Managed property-value error after about 30 s | Cancellation output corrupted the structured result; repaired below |
| discovery-fixed.stdout.txt | Get-FileHash unavailable before native work | Hidden PS5.1 child inherited PS7 module paths; no discovery in this attempt |
| discovery-hidden.json | Unknown/3; 30 s timeout; cancellation requested without error | Hidden PS5.1 with standard child module paths; pending native outcome preserved |
| discovery-address-filter.json | Unknown/3; timeout then TaskCanceledException | Exact-address AQS query did not complete within bound |
| discovery-mta.json | Unknown/3; timeout; cancellation requested; terminal observed | MTA threading did not resolve completion timeout |

No agent PairAsync or UnpairAsync call occurred. These results do not prove the ESP32 is absent; enumeration did not complete. User subsequently confirmed that Windows Settings Add device lists S3-HID-KM-v7. After the manual Settings action was requested, the user supplied [q twice](operator-serial-q-2026-09-27.md): connected=yes, keyboard_sub=yes, mouse_sub=no. The Windows final pairing status and mouse acceptance remain unverified.

The first result's top-level timeout wording is misleading: its operation record shows E_ACCESSDENIED after 188 ms with timedOut=false. Preserve that original artifact; the later software repair corrected the error reporting.

## Software repair

IAsyncInfo.Cancel reflection returned a literal null to the success pipeline, adding a second item before the operation record on timeout. Suppressed output inside Stop-BleOperation and both call sites. Tests cover explicit-null cancellation and zero output from actual existing-file WinRT cancellation. Discovery exception messages now preserve the native failure instead of implying every failure is a timeout.

Validated exact-address AQS filtering now narrows the query before enumeration, retaining post-filter exact matching and the three-argument AEP overload. [Microsoft selector guidance](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/build-a-device-selector) and [AEP properties](https://learn.microsoft.com/en-us/windows/apps/develop/devices-sensors/device-information-properties) were checked 2026-09-27. This did not resolve the observed timeout.

40 PS5.1/Pester 3.4 tests passed. The report from `build/pairing-development/tests-20260927T110242693Z.json` is retained unchanged as [pairing-tests-2026-09-27.json](pairing-tests-2026-09-27.json). Independent read-only review confirmed the cancellation-output mechanism and fix. Firmware remained unchanged.

## Launch preference

User reported PowerShell windows stealing keyboard focus. Hidden child launches and redirected output did not eliminate the reported pop-ups. Launching PS5.1 from the PS7 tool shell required standard Windows PowerShell module paths supplied to the child; no persistent environment or permission changes were made. A later user-authorized managed-session command, Write-Output 'background-check', returned background-check with exit 0. That confirms execution only; its actual runtime and window behavior were not separately verified. The earlier inferred blanket shell hold and unauthorized master-file additions were rolled back at the user's direction. During publication checks, the PS5.1 test guard rejected the command tool's requested shell; an explicit hidden PS5.1 child ran all tests successfully. See [closeout validation](closeout-validation-2026-09-27.md).
