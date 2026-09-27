<#
.SYNOPSIS
Discover or pair one explicitly addressed BLE Association Endpoint on WINSTONDESKTOP.
.EXAMPLE
  .\Invoke-BleAutoPair.ps1 -BleAddress 'AA:BB:CC:DD:EE:FF' -DiscoverOnly
.EXAMPLE
  .\Invoke-BleAutoPair.ps1 -BleAddress 'AA:BB:CC:DD:EE:FF' -Unpair -Pair -ResultPath build\pair-result.json
.NOTES
Run locally in interactive Windows PowerShell 5.1. Windows may display consent UI.
No arguments prints usage and makes no native calls. DeviceName is only a label.
Exit codes: 0 verified completion/usage, 1 failure, 2 invalid input/runtime, 3 unknown.
#>
[CmdletBinding()]
param([string]$BleAddress, [string]$DeviceName='S3-HID-KM-v7', [switch]$Pair,
    [switch]$Unpair, [switch]$DiscoverOnly, [string]$ResultPath)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'BlePairing.psm1') -Force
if (-not $BleAddress -and -not $Pair -and -not $Unpair -and -not $DiscoverOnly) {
    Write-Host 'Usage: .\Invoke-BleAutoPair.ps1 -BleAddress AA:BB:CC:DD:EE:FF [-DiscoverOnly | -Pair | -Unpair [-Pair]] [-ResultPath path]'
    Write-Host 'Confirm the target with serial i, then use b to advertise. An address alone defaults to pairing.'
    exit 0
}
try {
    $scriptHash=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    $moduleHash=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'BlePairing.psm1') -Algorithm SHA256).Hash
    if ($ResultPath -and (Test-Path -LiteralPath $ResultPath)) { throw 'ResultPath already exists; choose a fresh evidence path.' }
} catch { Write-Warning $_; exit 2 }
$result = Invoke-BlePairing -BleAddress $BleAddress -DeviceName $DeviceName -Pair:$Pair -Unpair:$Unpair -DiscoverOnly:$DiscoverOnly
$result | Add-Member -NotePropertyName scriptSha256 -NotePropertyValue $scriptHash
$result | Add-Member -NotePropertyName moduleSha256 -NotePropertyValue $moduleHash
$result | ConvertTo-Json -Depth 12 | Write-Output
if ($ResultPath) {
    try { Write-BleJson -Value $result -Path $ResultPath }
    catch { Write-Warning "Could not write result: $($_.Exception.Message)"; exit $(if ($result.exitCode -eq 3) { 3 } else { 2 }) }
}
Write-Host 'Inspect serial q for connected=yes, keyboard_sub=yes, mouse_sub=yes. mouse_sub=yes remains mandatory before any operator-authorized mouse diagnostic.'
Write-Host 'Windows unpairing does not establish that the ESP32 stored bonds were erased.'
exit $result.exitCode
