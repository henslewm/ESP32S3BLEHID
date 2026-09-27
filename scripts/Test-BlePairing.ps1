<# Runs static and mocked tests only. The real WinRT bridge test reads an existing local file; it never uses Bluetooth. #>
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.ToString() -notlike '5.1.*') { throw 'Run tests with Windows PowerShell 5.1.' }
$root=Split-Path $PSScriptRoot -Parent
foreach ($name in @('Invoke-BleAutoPair.ps1','BlePairing.psm1','Invoke-BlePairingJournal.ps1','BlePairingTelemetry.psm1')) {
    $tokens=$null; $problems=$null
    $null=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name),[ref]$tokens,[ref]$problems)
    if ($problems.Count) { throw ($problems | Out-String) }
}
Import-Module Pester -RequiredVersion 3.4.0
$result=Invoke-Pester -Script (Join-Path $root 'tests/BlePairing.Tests.ps1'),(Join-Path $root 'tests/BlePairingTelemetry.Tests.ps1') -PassThru
if ($null -eq $result) { throw 'Pester returned no result.' }
Import-Module (Join-Path $PSScriptRoot 'BlePairing.psm1') -Force
$path=Join-Path $root ('build/pairing-development/tests-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '.json')
# Pester 3.4 NUnit export queries restricted WMI; use its returned results directly.
Write-BleJson @{ utc=[DateTime]::UtcNow.ToString('o'); host=$env:COMPUTERNAME; powershell=$PSVersionTable.PSVersion.ToString()
    pester='3.4.0'; passed=$result.PassedCount; failed=$result.FailedCount; skipped=$result.SkippedCount
    evidenceLevel='static and mocked unit; existing-file WinRT bridge; no Bluetooth or hardware acceptance' } $path
Write-Host "Test evidence: $path"
if ($result.FailedCount -gt 0) { exit 1 }
exit 0
