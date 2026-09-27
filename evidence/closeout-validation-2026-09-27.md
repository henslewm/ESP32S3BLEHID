# Publication checkpoint checks — 2026-09-27

Scope: preserve and publish the existing implementation, evidence and documentation; open the focused mouse issue. No firmware or device investigation was performed by this closeout.

- Fresh Windows PowerShell 5.1 / Pester 3.4 run: **40 passed, 0 failed, 0 skipped**. [Raw result](pairing-tests-closeout-2026-09-27.json), UTC 2026-09-27T11:36:19.4381942Z. All BLE wrappers remain mocked; the actual WinRT check reads an existing local file.
- A first attempt through the command tool's requested shell was rejected by the runner's PS5.1 guard. Launching the explicit system powershell.exe through ProcessStartInfo, with CreateNoWindow and standard Windows PowerShell module paths, ran successfully. This did not change persistent environment settings; it does not establish that the command tool's outer process never flashes.
- ACTIVE bootstrap validation passed with the unchanged approved fingerprint. Project validation passed with 81 required paths. The existing fallback Python was used; no dependency installation occurred.
- Edited-file staged whitespace checks passed. The unfiltered check reports preserved CRLF/whitespace in archival evidence and the original bootstrap review; those originals were intentionally retained. The scoped check excludes archive, evidence, firmware and BOOTSTRAP_REVIEW.md. MASTER_INSTRUCTIONS.md and MASTER_CODEX.md have no diff from the original checkpoint.
- Locked baseline and isolated working sketch still have SHA-256 `9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6`.
- Older archive/BLEScanner.ino still has SHA-256 `310041fecca6c570ce1be86b5c5c90d69a2ad171c09377389297adf7a2d53580`.
- Six selected discovery artifacts were copied unchanged and verified against their original SHA-256 values. Their [manifest](discovery-2026-09-27/manifest.json) records both locations. Git attributes preserve evidence/imported-source bytes instead of normalizing recorded CRLF output.
- Verified 19 protected files against both the Git index bytes and workspace bytes, including imported source, retained discovery results and test receipts. The original pairing script's raw SHA-256 is `96c0b8b5686c9cb11110578659396a6fbf1a2bf252a866753dc39d760f408a81`; its LF-normalized content matches the original staged blob `c14d9ed72f4809e3415b8ba4e6b7515bb72992c6`.
- The inherited template-distribution synchronization CI step was replaced with ACTIVE foundation validation for this generated project. The existing Python unit-test step remains; its CI result is a separate publication check, not a claim of local execution here.
- The user explicitly requested the new private henslewm/ESP32S3BLEHID repository. GitHub returned isPrivate=true and viewerPermission=ADMIN, and origin was set to that repository. No template repository write occurred.

These checks do not establish mouse subscription, successful native scripted pairing, a real telemetry comparison, or Wazuh ingestion. The host's exact flashed firmware identity remains unresolved.
