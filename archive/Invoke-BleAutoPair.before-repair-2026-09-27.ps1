# ============================================================================
# Invoke-BleAutoPair.ps1
# Target: Win11 lab box (192.168.77.30) - run from an elevated PowerShell,
# an RDP session, or via Sliver's powershell invoker.
#
# Purpose: automate the ONE manual step of the BLE HID workflow - pairing the
# ESP32-S3 ("S3-NimBLE-Research", Just Works) with Windows - so the whole
# enrollment is scriptable and scoreable in Wazuh/Sysmon.
#
# IMPORTANT - this script is the THIRD-PARTY-FREE variant.
# The "Bluetooth Command Line Tools" suite (btpair.exe) is closed-source
# freeware from bluetoothinstaller.com; there is no GitHub repo to legally
# embed code from. This script reproduces its pairing capability using the
# built-in Windows Runtime (WinRT) Bluetooth APIs instead - nothing is
# dropped on disk except this .ps1, which keeps your process-creation
# telemetry clean and attributable.
#
# If you DO want the btpair variant for comparison, install the suite and
# the equivalent is simply:  btpair -p -b 7c:4f:ad:21:52:89
# (the -p PIN argument is ignored for Just Works BLE - no prompt appears)
#
# Usage:
#   .\Invoke-BleAutoPair.ps1                 # pair (MAC below is hardcoded)
#   .\Invoke-BleAutoPair.ps1 -Unpair         # remove the bond first
#   .\Invoke-BleAutoPair.ps1 -Unpair -Pair    # clean re-pair (scoring runs)
#
# Scoring note: run Manual-UI pair vs this script as separate journal runs.
# Sysmon Event 1 / PowerShell ScriptBlock (4104) will fire for THIS path
# but not for the Settings-UI path - that contrast is a deliverable.
# ============================================================================

param(
    # Hardcoded per the lab decision: the S3's public BLE address is stable
    # (eFuse base MAC + 2). Verify once against the sketch's 'i' command
    # ("Own BLE address") and paste the string here.
    [string]$BleAddress = '7c:4f:ad:21:52:89',

    # Optional friendly-name path instead of MAC (survives a re-flash that
    # changes the address; matches how a real adversary script targets HID).
    [string]$DeviceName = 'S3-HID-KM-v7',

    [switch]$Pair,
    [switch]$Unpair
)

$ErrorActionPreference = 'Stop'

# --- WinRT async plumbing (PowerShell cannot await IAsyncOperation natively)
$null = [Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]
$null = [Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
$null = [Windows.Devices.Enumeration.DevicePairingResultStatus, Windows.Devices.Enumeration, ContentType = WindowsRuntime]

Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue

function Await($WinRtTask, $ResultType) {
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
                       $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

function Parse-Mac([string]$Mac) {
    # BluetoothAddress is a ulong, MSB first.
    [uint64]([System.Convert]::ToUInt64(($Mac -replace ':', ''), 16))
}

function Get-LeDevice([string]$Mac) {
    $addr = Parse-Mac $Mac
    $dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) `
               ([Windows.Devices.Bluetooth.BluetoothLEDevice])
    if ($null -eq $dev) {
        throw "FromBluetoothAddressAsync returned null. Is the S3 in HID advertise mode (serial 'b') and in range?"
    }
    $dev
}

function Remove-ExistingBond([string]$Mac) {
    # Clean the bond table so each scoring run starts from zero.
    $mac = $Mac -replace ':', ''
    $paired = Get-PnpDevice -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match "DEV_$mac" -or ($_.FriendlyName -eq $DeviceName) }
    foreach ($d in $paired) {
        Write-Host "[*] Removing existing bond: $($d.FriendlyName) ($($d.InstanceId))"
        # Use pnputil to remove the paired device node (Win11 has /remove-device)
        pnputil /remove-device "$($d.InstanceId)" | Out-Null
    }
    if ($paired) { Start-Sleep -Seconds 2 }
}

# --- Main -------------------------------------------------------------------

if (-not ($Pair -or $Unpair)) { $Pair = $true }   # default action = pair

if ($Unpair) {
    Write-Host "[*] Unpairing $BleAddress ..."
    Remove-ExistingBond -Mac $BleAddress
    Write-Host "[+] Unpair complete."
    if (-not $Pair) { return }
}

Write-Host "[*] Attempting WinRT pairing to $BleAddress ($DeviceName) ..."
Write-Host "[*] Ensure the S3 is in HID mode (serial 'b' -> advertising 0x1812)."

# IMPORTANT (fix for "PairAsync status: Failed"):
# Pairing from BluetoothLEDevice.DeviceId fails on Win11 for many LE HID
# peripherals. The reliable pairing object is the Bluetooth-LE AEP
# (Association Endpoint) DeviceInformation that Windows only creates while
# the device is ACTIVELY advertising. Protocol GUID
# {bb7bb05e-5972-42b5-94fc-76eaa7084d49} = Bluetooth LE AEP container.
$null = [Windows.Devices.Enumeration.DeviceInformationCollection, Windows.Devices.Enumeration, ContentType = WindowsRuntime]

$aepSelector = 'System.Devices.Aep.ProtocolId:="{bb7bb05e-5972-42b5-94fc-76eaa7084d49}"'
$info = $null

for ($attempt = 1; $attempt -le 3 -and $null -eq $info; $attempt++) {
    $aeps = Await ([Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($aepSelector)) `
               ([Windows.Devices.Enumeration.DeviceInformationCollection])
    $info = $aeps | Where-Object { $_.Name -eq $DeviceName } | Select-Object -First 1
    if ($null -eq $info) {
        # Also match on address in case the GAP name was changed in firmware.
        $info = $aeps | Where-Object { $_.Properties['System.Devices.Aep.DeviceAddress'] -replace ':','' -eq ($BleAddress -replace ':','') } | Select-Object -First 1
    }
    if ($null -eq $info -and $attempt -lt 3) {
        Write-Host "[*] AEP not visible yet (attempt $attempt/3). Is the S3 in 'b' mode? Retrying in 5 s..."
        Start-Sleep -Seconds 5
    }
}

if ($null -eq $info) {
    # Fallback: connect by MAC, then pair from its DeviceId (older behavior).
    try {
        $le = Get-LeDevice -Mac $BleAddress
        $info = Await ([Windows.Devices.Enumeration.DeviceInformation]::CreateFromIdAsync($le.DeviceId)) `
                   ([Windows.Devices.Enumeration.DeviceInformation])
        Write-Host "[*] AEP lookup failed; pairing via BluetoothLEDevice fallback path."
    } catch {
        throw "Device '$DeviceName' not visible as a Bluetooth LE AEP. Confirm the S3 is in 'b' advertise mode."
    }
}

Write-Host "[*] Pairing object Id: $($info.Id)"

Write-Host "[*] Device found: $($info.Name)  Paired=$($info.Pairing.IsPaired)  CanPair=$($info.Pairing.CanPair)"

if ($info.Pairing.IsPaired) {
    Write-Host "[+] Already bonded. (Windows will auto-reconnect whenever the S3 advertises.)"
    return
}

if (-not $info.Pairing.CanPair) {
    throw "Pairing not permitted for this device. Confirm the S3 is advertising connectable HID (0x1812)."
}

# Just Works: no UI prompt for LE HID with NoInputNoOutput peripheral.
$result = Await ($info.Pairing.PairAsync()) ([Windows.Devices.Enumeration.DevicePairingResult])

switch ($result.Status) {
    'Paired'  { Write-Host "[+] PAIRED (Just Works, no PIN). HID drivers should now enumerate." }
    'AlreadyPaired' { Write-Host "[+] Was already paired." }
    default {
        Write-Warning "[-] PairAsync status: $($result.Status)"
        Write-Host "Hints: S3 must be in 'b' advertise mode; BLE address must match sketch 'i' output."
        throw "Pairing failed."
    }
}

# Post-check: wait briefly for the HID child devices to enumerate.
Start-Sleep -Seconds 5
$hidDev = Get-PnpDevice -Class HIDClass -ErrorAction SilentlyContinue |
    Where-Object { $_.Status -eq 'OK' -and $_.InstanceId -match ($BleAddress -replace ':','') }
if ($hidDev) {
    Write-Host "[+] HID device nodes active: $($hidDev.Count). Press 't' on the S3 serial to inject."
} else {
    Write-Host "[i] No HID child node yet - check Get-PnpDevice -Class HIDClass manually."
}

Write-Host "[*] Detection cross-check on this box:"
Write-Host "    Get-WinEvent -LogName 'Microsoft-Windows-DriverFrameworks-UserPnp/Operational' -MaxEvents 20"
Write-Host "    Get-WinEvent -LogName 'Microsoft-Windows-Bluetooth-BthLEPrepairing/Operational' -MaxEvents 20 -ErrorAction SilentlyContinue"