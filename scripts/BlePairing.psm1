Set-StrictMode -Version 2.0

function ConvertTo-BleAddress {
    param([string]$Address)
    $value = $Address.Trim()
    if ($value -notmatch '^(?:[0-9a-fA-F]{12}|(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|(?:[0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2})$') {
        throw 'BleAddress must be exactly 48 bits: twelve hex digits, or six colon/hyphen separated hex pairs.'
    }
    $hex = ($value -replace '[:-]', '').ToUpperInvariant()
    return (($hex -split '(.{2})' | Where-Object { $_ }) -join ':')
}

function Write-BleJson {
    param($Value, [string]$Path)
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full))
    $stream = [IO.File]::Open($full, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    $writer = New-Object IO.StreamWriter($stream, (New-Object Text.UTF8Encoding($false)))
    try { $writer.WriteLine(($Value | ConvertTo-Json -Depth 20)) } finally { $writer.Dispose() }
}

function Initialize-BleRuntime {
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
        throw 'Use Windows PowerShell 5.1 (powershell.exe), not pwsh.'
    }
    if ($env:COMPUTERNAME -ne 'WINSTONDESKTOP') { throw 'This operator workflow targets WINSTONDESKTOP only.' }
    if (-not [Environment]::UserInteractive -or (Get-Process -Id $PID).SessionId -eq 0 -or (Get-Variable PSSenderInfo -ErrorAction SilentlyContinue)) {
        throw 'Run locally in an interactive desktop session; remote or service execution is unsupported.'
    }
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.Foundation.IAsyncInfo, Windows.Foundation, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Enumeration.DeviceInformationKind, Windows.Devices.Enumeration, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Enumeration.DeviceInformationCollection, Windows.Devices.Enumeration, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Enumeration.DevicePairingResult, Windows.Devices.Enumeration, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Enumeration.DeviceUnpairingResult, Windows.Devices.Enumeration, ContentType=WindowsRuntime]
    $null = [Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType=WindowsRuntime]
    # The custom-pairing helper needs the Windows SDK; it is loaded only when a Pair mutation starts,
    # so discovery and unpair-only runs work on hosts without it.
}

function Import-BleCustomPairing {
    # Compiles scripts/BleCustomPairing.cs once into build/pairing (ignored) and loads it.
    if ('BleCustomPairing' -as [type]) { return }
    $source = Join-Path $PSScriptRoot 'BleCustomPairing.cs'
    $outDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'build\pairing'
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.Substring(0, 12)
    $dll = Join-Path $outDir "BleCustomPairing-$hash.dll"
    if (-not (Test-Path -LiteralPath $dll)) {
        # Versioned SDK folders only; UnionMetadata\Facade holds a forwarding stub that cannot be compiled against.
        $winmd = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\UnionMetadata\*\Windows.winmd' -ErrorAction SilentlyContinue |
            Where-Object { $_.Directory.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Directory.Name } -Descending | Select-Object -First 1
        if ($null -eq $winmd) { throw 'Windows SDK UnionMetadata\Windows.winmd is required to build the pairing helper.' }
        $gac = Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL'
        $refs = @(
            $winmd.FullName,
            (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\System.Runtime.WindowsRuntime.dll'),
            (Get-ChildItem (Join-Path $gac 'System.Runtime') -Recurse -Filter System.Runtime.dll | Select-Object -First 1).FullName,
            (Get-ChildItem (Join-Path $gac 'System.Runtime.InteropServices.WindowsRuntime') -Recurse -Filter *.dll | Select-Object -First 1).FullName
        )
        $null = [IO.Directory]::CreateDirectory($outDir)
        $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
        $output = & $csc /nologo /target:library "/out:$dll" ($refs | ForEach-Object { "/r:$_" }) $source 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Pairing helper build failed: $($output -join ' ')" }
    }
    Add-Type -Path $dll
}

function Get-BleException {
    param([Exception]$Exception)
    $base = $Exception.GetBaseException()
    [pscustomobject]@{ type=$base.GetType().FullName; message=$base.Message; hresult=('0x{0:X8}' -f $base.HResult) }
}

function ConvertTo-BleTask {
    param($Operation, [Type]$ResultType)
    $method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } | Select-Object -First 1
    return $method.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
}
function Wait-BleTask { param($Task, [int]$Milliseconds) return $Task.Wait($Milliseconds) }
function Stop-BleOperation {
    param($Operation)
    # PS 5.1 projects this as System.__ComObject; Cancel is an IAsyncInfo method.
    # Reflection returns an explicit null for void; suppress it so cancellation
    # cannot add a second item to the caller's structured result pipeline.
    $null = [Windows.Foundation.IAsyncInfo].GetMethod('Cancel').Invoke($Operation, @())
}

function Complete-BleOperation {
    param($Record)
    if ($null -ne $Record.task -and $Record.task.IsCompleted) {
        $Record.terminal = $true
        $Record.terminalObservedUtc = [DateTime]::UtcNow.ToString('o')
        try {
            $Record.value = $Record.task.GetAwaiter().GetResult()
            if ($null -ne $Record.value -and $Record.value.PSObject.Properties['Status']) { $Record.nativeStatus = [string]$Record.value.Status }
        } catch { $Record.exception = Get-BleException $_.Exception }
    }
    return $Record
}

function Invoke-BleNativeOperation {
    param([scriptblock]$Start, [Type]$ResultType, [int]$TimeoutSeconds, [string]$Method)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $record = [pscustomobject]@{
        method=$Method; startedUtc=[DateTime]::UtcNow.ToString('o'); endedUtc=$null; elapsedMs=0
        nativeStatus=$null; exception=$null; timedOut=$false; cancellationRequested=$false
        cancellationError=$null; terminal=$false; terminalObservedUtc=$null; task=$null; operation=$null; value=$null
    }
    try {
        $record.operation = & $Start
        $record.task = ConvertTo-BleTask $record.operation $ResultType
        $remaining = [Math]::Max(0, $TimeoutSeconds * 1000 - [int]$watch.ElapsedMilliseconds)
        if (-not (Wait-BleTask $record.task $remaining)) {
            $record.timedOut = $true; $record.cancellationRequested = $true
            try { $null = Stop-BleOperation $record.operation } catch { $record.cancellationError = Get-BleException $_.Exception }
        }
    } catch {
        $record.exception = Get-BleException $_.Exception
        $record.terminal = ($null -eq $record.operation)
        if ($null -ne $record.operation -and $null -eq $record.task) {
            $record.cancellationRequested = $true
            try { $null = Stop-BleOperation $record.operation } catch { $record.cancellationError = Get-BleException $_.Exception }
        }
    }
    $record = Complete-BleOperation $record
    $watch.Stop(); $record.elapsedMs = $watch.ElapsedMilliseconds; $record.endedUtc = [DateTime]::UtcNow.ToString('o')
    return $record
}

function Get-BleOperationEvidence {
    param($Record)
    $Record | Select-Object method,startedUtc,endedUtc,elapsedMs,nativeStatus,exception,timedOut,cancellationRequested,cancellationError,terminal,terminalObservedUtc
}

function Get-BleAepSelector {
    param([string]$Address)
    $selector = 'System.Devices.Aep.ProtocolId:="{bb7bb05e-5972-42b5-94fc-76eaa7084d49}"'
    if ($Address) {
        $normalized = ConvertTo-BleAddress $Address
        $selector += ' AND System.Devices.Aep.DeviceAddress:="' + $normalized + '"'
    }
    return $selector
}

function Get-BleDiscovery {
    param([string]$Address)
    $properties = [string[]]@('System.Devices.Aep.DeviceAddress','System.Devices.Aep.IsPaired',
        'System.Devices.Aep.IsPresent','System.Devices.Aep.Bluetooth.Le.IsConnectable')
    if ($Address) {
        # Exact-address lookup. FindAllAsync over unpaired LE AEPs did not complete
        # within 30 s on this host; opening the device by address returns in ~50 ms.
        $raw = [Convert]::ToUInt64(($Address -replace ':', ''), 16)
        $open = Invoke-BleNativeOperation -Method FromBluetoothAddressAsync -TimeoutSeconds 30 -ResultType ([Windows.Devices.Bluetooth.BluetoothLEDevice]) -Start {
            [Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($raw)
        }
        if ($open.exception -or $open.timedOut -or $null -eq $open.value) {
            return [pscustomobject]@{ operation=$open; devices=@() }
        }
        $deviceId = $open.value.DeviceId
        $record = Invoke-BleNativeOperation -Method CreateFromIdAsync -TimeoutSeconds 30 -ResultType ([Windows.Devices.Enumeration.DeviceInformation]) -Start {
            [Windows.Devices.Enumeration.DeviceInformation]::CreateFromIdAsync($deviceId, $properties,
                [Windows.Devices.Enumeration.DeviceInformationKind]::AssociationEndpoint)
        }
        # Never pipe the WinRT object: PowerShell enumerates it as its property bag.
        $devices = @()
        if ($null -ne $record.value) { $devices = @(,$record.value) }
        return [pscustomobject]@{ operation=$record; devices=$devices }
    }
    $selector = Get-BleAepSelector $Address
    $record = Invoke-BleNativeOperation -Method FindAllAsync -TimeoutSeconds 30 -ResultType ([Windows.Devices.Enumeration.DeviceInformationCollection]) -Start {
        [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($selector, $properties,
            [Windows.Devices.Enumeration.DeviceInformationKind]::AssociationEndpoint)
    }
    [pscustomobject]@{ operation=$record; devices=@($record.value) }
}

function Get-BleProperty {
    param($Device, [string]$Name)
    $bag = $Device.Properties
    if ($null -eq $bag) { return $null }
    if ($bag -is [System.Collections.IDictionary]) {
        if ($bag.Contains($Name)) { return $bag[$Name] }
        return $null
    }
    # WinRT IMapView projects to PS 5.1 as an enumerable of key/value pairs without ContainsKey.
    foreach ($entry in $bag) { if ($entry.Key -eq $Name) { return $entry.Value } }
    return $null
}

function ConvertTo-BleDeviceRecord {
    param($Device)
    $address = Get-BleProperty $Device 'System.Devices.Aep.DeviceAddress'
    try { $address = ConvertTo-BleAddress $address } catch { $address = $null }
    [pscustomobject]@{
        address=$address; name=$Device.Name; aepId=$Device.Id; kind=[string]$Device.Kind
        isPaired=$Device.Pairing.IsPaired; canPair=$Device.Pairing.CanPair
        isPresent=(Get-BleProperty $Device 'System.Devices.Aep.IsPresent')
        isConnectable=(Get-BleProperty $Device 'System.Devices.Aep.Bluetooth.Le.IsConnectable')
    }
}

function Select-BleExactDevice {
    param([object[]]$Devices, [string]$Address)
    $matches = @($Devices | Where-Object {
        if ($null -ne $_) {
            $candidate = ConvertTo-BleDeviceRecord $_
            $candidate.address -eq $Address -and $candidate.kind -eq 'AssociationEndpoint'
        }
    })
    if ($matches.Count -gt 1) { throw 'Ambiguous exact-address Association Endpoints; no mutation is permitted.' }
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Invoke-BleMutation {
    param($Device, [ValidateSet('Pair','Unpair')][string]$Action)
    if ($Action -eq 'Unpair') {
        return Invoke-BleNativeOperation -Method UnpairAsync -TimeoutSeconds 120 -ResultType ([Windows.Devices.Enumeration.DeviceUnpairingResult]) -Start { $Device.Pairing.UnpairAsync() }
    }
    # Custom ConfirmOnly pairing accepts the Just Works prompt in-process; plain PairAsync fails without UI.
    return Invoke-BleNativeOperation -Method CustomPairAsync -TimeoutSeconds 120 -ResultType ([Windows.Devices.Enumeration.DevicePairingResult]) -Start { Import-BleCustomPairing; [BleCustomPairing]::StartConfirmOnlyPair($Device) }
}

function Invoke-BlePairing {
    [CmdletBinding()]
    param([string]$BleAddress, [string]$DeviceName='S3-HID-KM-v7', [switch]$Pair, [switch]$Unpair, [switch]$DiscoverOnly)
    $result = [pscustomobject]@{
        schemaVersion=1; startedUtc=[DateTime]::UtcNow.ToString('o'); endedUtc=$null
        hostName=$env:COMPUTERNAME; processId=$PID; address=$null; nameLabel=$DeviceName
        outcome='failed'; exitCode=2; message=''; exception=$null; operations=@(); devices=@(); stateBefore=$null; stateAfter=$null
    }
    $mutationStarted = $false
    $handledOutcome = $false
    try {
        if ($DiscoverOnly -and ($Pair -or $Unpair)) { throw 'DiscoverOnly cannot be combined with Pair or Unpair.' }
        if ($BleAddress) { $result.address = ConvertTo-BleAddress $BleAddress }
        elseif (-not $DiscoverOnly) { throw 'An explicit BleAddress is required for pairing or unpairing.' }
        Initialize-BleRuntime
        $result.exitCode = 1
        $discovery = Get-BleDiscovery -Address $result.address
        $result.operations += Get-BleOperationEvidence $discovery.operation
        if ($discovery.operation.exception) {
            $result.exitCode=3; $result.outcome='unknown'; throw "Discovery failed: $($discovery.operation.exception.message)"
        }
        if ($discovery.operation.timedOut) {
            $result.exitCode=3; $result.outcome='unknown'; throw 'Discovery did not complete reliably within 30 seconds.'
        }
        $result.devices = @($discovery.devices | Where-Object { $null -ne $_ } | ForEach-Object { ConvertTo-BleDeviceRecord $_ })
        $device = $null
        if ($result.address) { $device = Select-BleExactDevice $discovery.devices $result.address }
        if ($DiscoverOnly) {
            if ($result.address -and $null -eq $device) { throw 'No exact-address AEP found. Confirm serial i and advertising b.' }
            $result.outcome='succeeded'; $result.exitCode=0; $result.message='Discovery completed; no device state was changed.'
            return $result
        }
        if ($null -eq $device) { throw 'No exact-address AEP found. Confirm serial i and advertising b.' }
        $result.stateBefore = ConvertTo-BleDeviceRecord $device
        if (-not $Unpair -and -not $Pair) { $Pair = $true }
        $actions = @()
        if ($Unpair) { $actions += 'Unpair' }
        if ($Pair) { $actions += 'Pair' }
        foreach ($action in $actions) {
            $desired = $action -eq 'Pair'; $operation = $null
            $already = $device.Pairing.IsPaired -eq $desired
            if (-not $already) {
                if ($desired -and -not $device.Pairing.CanPair) { throw 'Exact target reports CanPair=false.' }
                $mutationStarted = $true
                $operation = Invoke-BleMutation $device $action
                $result.operations += Get-BleOperationEvidence $operation
            }
            $fresh = Get-BleDiscovery -Address $result.address
            $result.operations += Get-BleOperationEvidence $fresh.operation
            if ($null -ne $operation) {
                $operation = Complete-BleOperation $operation
                # Update retained mutation evidence without losing it if the postcheck throws.
                $result.operations[$result.operations.Count - 2] = Get-BleOperationEvidence $operation
            }
            if ($fresh.operation.exception -or $fresh.operation.timedOut) {
                $result.outcome='unknown'; $result.exitCode=3; throw 'Postcheck discovery was inconclusive; do not retry automatically.'
            }
            try { $device = Select-BleExactDevice $fresh.devices $result.address }
            catch { $result.outcome='unknown'; $result.exitCode=3; throw }
            if ($null -eq $device) { $result.outcome='unknown'; $result.exitCode=3; throw 'Exact target absent during postcheck; do not retry automatically.' }
            $result.stateAfter = ConvertTo-BleDeviceRecord $device
            $confirmed = $result.stateAfter.isPaired -eq $desired
            if ($null -ne $operation) {
                if (-not $operation.terminal) { $result.outcome='unknown'; $result.exitCode=3; throw 'Native operation may still be pending after cancellation; no automatic retry or re-pair.' }
                if ($operation.nativeStatus -eq 'OperationAlreadyInProgress') { $result.outcome='unknown'; $result.exitCode=3; throw 'Windows reports another pair/unpair operation in progress; no automatic retry.' }
                $accepted = if ($desired) { @('Paired','AlreadyPaired') } else { @('Unpaired','AlreadyUnpaired') }
                $nativeSuccess = -not $operation.exception -and $operation.nativeStatus -in $accepted
                if (-not $nativeSuccess) {
                    $handledOutcome = $true
                    if ($confirmed) { $result.outcome='unknown'; $result.exitCode=3 }
                    throw "Native $action status: $($operation.nativeStatus). See exception and refreshed state."
                }
            }
            if (-not $confirmed) { $result.outcome='unknown'; $result.exitCode=3; throw 'Native/previous state and fresh exact-device state disagree; no automatic retry.' }
        }
        $result.outcome='succeeded'; $result.exitCode=0; $result.message='Requested Windows state verified for the exact address. HID subscription still requires serial q.'
    } catch {
        $result.message = $_.Exception.Message
        $result.exception = Get-BleException $_.Exception
        if ($mutationStarted -and -not $handledOutcome) { $result.exitCode=3; $result.outcome='unknown' }
    } finally { $result.endedUtc = [DateTime]::UtcNow.ToString('o') }
    return $result
}
Export-ModuleMember -Function ConvertTo-BleAddress,Write-BleJson,Invoke-BlePairing
