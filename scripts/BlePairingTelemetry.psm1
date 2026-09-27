Set-StrictMode -Version 2.0

function Add-JournalEvent {
    param([string]$Path, $Value)
    [IO.File]::AppendAllText($Path, (($Value | ConvertTo-Json -Depth 16 -Compress) + [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))
}

function Get-JournalChannel {
    param([string]$Name)
    $record = [pscustomobject]@{ name=$Name; available=$false; enabled=$false; logType=$null; logMode=$null
        oldest=0L; newest=0L; count=0L; error=$null }
    try {
        $log = Get-WinEvent -ListLog $Name -Force -ErrorAction Stop
        $record.available=$true; $record.enabled=$log.IsEnabled; $record.logType=[string]$log.LogType
        $record.logMode=[string]$log.LogMode; $record.count=[long]$log.RecordCount; $record.oldest=[long]$log.OldestRecordNumber
        if ($record.enabled -and $record.count -gt 0) {
            if ($record.logType -in @('Analytical','Debug')) {
                # Record IDs are not assumed contiguous. These channels are reported, not polled.
                $record.error='Analytic/debug channel is outside this Operational/Admin collector.'
            } else { $record.newest=[long](Get-WinEvent -LogName $Name -MaxEvents 1 -ErrorAction Stop).RecordId }
        }
    } catch { $record.error = $_.ToString() }
    return $record
}

function Get-JournalChannels {
    $names = @('Microsoft-Windows-PowerShell/Operational','Windows PowerShell','Microsoft-Windows-Sysmon/Operational',
        'Microsoft-Windows-Bluetooth-BthLEPrepairing/Operational','Microsoft-Windows-UserPnp/DeviceInstall','System')
    $errors = @()
    foreach ($pattern in @('*Bluetooth*','*BTH*','*UserPnp*')) {
        try { $names += @(Get-WinEvent -ListLog $pattern -Force -ErrorAction Stop | ForEach-Object { $_.LogName }) }
        catch { $errors += "$pattern : $($_.ToString())" }
    }
    [pscustomobject]@{ channels=@($names | Sort-Object -Unique | ForEach-Object { Get-JournalChannel $_ }); discoveryErrors=$errors }
}

function Get-JournalGap {
    param($Before, $After, [long]$Cursor)
    if (-not $After.available -or $After.error) { return 'Channel metadata became unavailable.' }
    if ($After.newest -lt $Cursor) { return 'Log reset/clear detected; record IDs moved backwards.' }
    if ($After.oldest -gt ($Cursor + 1) -and $Cursor -gt 0) { return 'Rollover may have removed unread records.' }
    if ($Before.enabled -and -not $After.enabled) { return 'Channel disabled during capture.' }
    return $null
}

function ConvertFrom-JournalEvent {
    param($Record)
    [xml]$xml = $Record.ToXml()
    $data = @{}
    foreach ($entry in @($xml.SelectNodes('//*[local-name()="EventData"]/*[local-name()="Data"]'))) {
        $data[$entry.GetAttribute('Name')] = $entry.InnerText
    }
    $system = $xml.Event.System
    $execution = $system.SelectSingleNode('*[local-name()="Execution"]')
    $eventPid = if ($null -ne $execution) { $execution.GetAttribute('ProcessID') } else { $null }
    [pscustomobject]@{ channel=$Record.LogName; provider=$Record.ProviderName; eventId=$Record.Id; recordId=$Record.RecordId
        utc=$Record.TimeCreated.ToUniversalTime().ToString('o'); computer=[string]$system.Computer
        systemProcessId=$eventPid; data=$data; rawXml=$Record.ToXml() }
}

function Start-JournalCapture {
    param([string]$RunDirectory, [int]$MaxSeconds=1200)
    $ErrorActionPreference='Stop'
    $inventory = Get-JournalChannels
    $states = @($inventory.channels | ForEach-Object {
        [pscustomobject]@{ before=$_; after=$null; cursor=$_.newest; errors=@(); gaps=@(); captured=0 }
    })
    $eventsPath = Join-Path $RunDirectory 'events.jsonl'
    [IO.File]::WriteAllText($eventsPath, '', (New-Object Text.UTF8Encoding($false)))
    $start = [DateTime]::UtcNow
    $ready = @{ processId=$PID; startedUtc=$start.ToString('o'); processStartUtc=(Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('o') }
    [IO.File]::WriteAllText((Join-Path $RunDirectory 'capture-ready.json'), ($ready | ConvertTo-Json))
    try {
        do {
            $finalPass = Test-Path -LiteralPath (Join-Path $RunDirectory 'capture-stop')
            foreach ($state in $states) {
                if (-not $state.before.available -or -not $state.before.enabled -or $state.before.error) { continue }
                $now = Get-JournalChannel $state.before.name
                $gap = Get-JournalGap $state.before $now $state.cursor
                if ($gap) {
                    if ($gap -notin $state.gaps) { $state.gaps += $gap }
                    if ($now.newest -lt $state.cursor) { $state.cursor=0L }
                }
                try {
                    $xpath = '*[System[EventRecordID > ' + $state.cursor + ']]'
                    $records = @(Get-WinEvent -LogName $state.before.name -FilterXPath $xpath -Oldest -MaxEvents 5000 -ErrorAction Stop)
                    if ($records.Count -eq 5000 -and 'Query cap reached; capture may lag.' -notin $state.gaps) { $state.gaps += 'Query cap reached; capture may lag.' }
                    foreach ($record in $records) {
                        $state.cursor = [Math]::Max($state.cursor, [long]$record.RecordId)
                        # System is broad; retain only applicable device providers.
                        if ($state.before.name -eq 'System' -and $record.ProviderName -notmatch 'Bluetooth|BTH|UserPnp|Kernel-PnP|DeviceSetupManager') { continue }
                        Add-JournalEvent $eventsPath (ConvertFrom-JournalEvent $record)
                        $state.captured++
                    }
                } catch {
                    if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
                        $state.errors += [pscustomobject]@{ utc=[DateTime]::UtcNow.ToString('o'); error=$_.ToString() }
                    }
                }
                $state.after=$now
            }
            if ($finalPass) { break }
            Start-Sleep -Milliseconds 500
        } while (([DateTime]::UtcNow - $start).TotalSeconds -lt $MaxSeconds)
    } finally {
        $stoppedNormally = Test-Path -LiteralPath (Join-Path $RunDirectory 'capture-stop')
        foreach ($state in $states) {
            $state.after = Get-JournalChannel $state.before.name
            $finalGap=Get-JournalGap $state.before $state.after $state.cursor
            if ($finalGap -and $finalGap -notin $state.gaps) { $state.gaps += $finalGap }
            if ($state.after.newest -gt $state.cursor) { $state.gaps += 'Records remained unread at final checkpoint; tail coverage is inconclusive.' }
            if (-not $stoppedNormally) { $state.gaps += 'Collector deadline/interruption; capture is incomplete.' }
        }
        $coverage = @{ startedUtc=$start.ToString('o'); endedUtc=[DateTime]::UtcNow.ToString('o'); collectorPid=$PID
            discoveryErrors=$inventory.discoveryErrors; channels=$states; normalStop=$stoppedNormally }
        [IO.File]::WriteAllText((Join-Path $RunDirectory 'coverage.json'), ($coverage | ConvertTo-Json -Depth 12))
    }
}

function Get-JournalProcess {
    param([Diagnostics.Process]$Process, [string]$Role)
    $path=$null; $hash=$null; $errorText=$null
    try { $path=$Process.MainModule.FileName; $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash }
    catch { $errorText=$_.ToString() }
    [pscustomobject]@{ role=$Role; processId=$Process.Id; processStartUtc=$Process.StartTime.ToUniversalTime().ToString('o')
        endUtc=$null; observedUntilUtc=[DateTime]::UtcNow.ToString('o'); lifetimeUncertain=$false
        image=$path; executableSha256=$hash; hashError=$errorText; processGuid=$null }
}

function Update-JournalLifetimes {
    param([object[]]$Processes)
    foreach ($proc in $Processes) {
        if ($proc.endUtc) { continue }
        try {
            $live=Get-Process -Id $proc.processId -ErrorAction Stop
            if ($live.StartTime.ToUniversalTime() -ne [DateTime]::Parse($proc.processStartUtc).ToUniversalTime()) {
                $proc.lifetimeUncertain=$true
            } else { $proc.observedUntilUtc=[DateTime]::UtcNow.ToString('o') }
        } catch { $proc.lifetimeUncertain=$true }
    }
}

function Get-JournalRole {
    param($Event, [object[]]$Processes)
    $sysmon = $Event.provider -eq 'Microsoft-Windows-Sysmon'
    $eventProcess = if ($sysmon) { $Event.data['ProcessId'] } else { $Event.systemProcessId }
    $when = [DateTime]::Parse($Event.utc).ToUniversalTime()
    foreach ($proc in $Processes) {
        if ([string]$proc.processId -ne [string]$eventProcess) { continue }
        # PowerShell events cannot be attributed to a Settings PID reused by a PowerShell process.
        if ($Event.provider -eq 'Microsoft-Windows-PowerShell' -and $proc.image -notmatch '(?i)[\\/](?:powershell|pwsh)\.exe$') { continue }
        if ($when -lt [DateTime]::Parse($proc.processStartUtc).ToUniversalTime()) { continue }
        if ($proc.endUtc -and $when -gt [DateTime]::Parse($proc.endUtc).ToUniversalTime()) { continue }
        if ($sysmon -and (-not $proc.processGuid -or $Event.data['ProcessGuid'] -ne $proc.processGuid)) { continue }
        if (-not $sysmon -and ($proc.lifetimeUncertain -or (-not $proc.endUtc -and $when -gt [DateTime]::Parse($proc.observedUntilUtc).ToUniversalTime()))) { continue }
        return $proc.role
    }
    return 'unattributed'
}

function Set-JournalProcessGuids {
    param([object[]]$Events, [object[]]$Processes)
    foreach ($proc in $Processes) {
        $matches = @($Events | Where-Object {
            $_.provider -eq 'Microsoft-Windows-Sysmon' -and $_.eventId -eq 1 -and
            [string]$_.data['ProcessId'] -eq [string]$proc.processId -and $_.data['Image'] -eq $proc.image -and
            $_.data['UtcTime'] -and [Math]::Abs(([DateTime]::Parse($_.data['UtcTime'], [Globalization.CultureInfo]::InvariantCulture,
                ([Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)) -
                [DateTime]::Parse($proc.processStartUtc).ToUniversalTime()).TotalMilliseconds) -lt 1
        })
        $guids = @($matches | ForEach-Object { $_.data['ProcessGuid'] } | Sort-Object -Unique)
        if ($guids.Count -eq 1) { $proc.processGuid=$guids[0] }
    }
}

function Join-JournalScriptBlocks {
    param([object[]]$Events)
    $groups = @($Events | Where-Object { $_.eventId -eq 4104 -and $_.provider -eq 'Microsoft-Windows-PowerShell' } |
        Group-Object { "$($_.computer)|$($_.systemProcessId)|$($_.role)|$($_.data['ScriptBlockId'])" })
    foreach ($group in $groups) {
        $totals = @($group.Group | ForEach-Object { [int]$_.data['MessageTotal'] } | Sort-Object -Unique)
        $parts = @{}; $conflict=$false
        foreach ($evt in $group.Group) {
            $number = [int]$evt.data['MessageNumber']; $content = [string]$evt.data['ScriptBlockText']
            if ($parts.ContainsKey($number) -and $parts[$number] -ne $content) { $conflict=$true }
            $parts[$number]=$content
        }
        $complete = $totals.Count -eq 1 -and $totals[0] -gt 0 -and $parts.Count -eq $totals[0] -and -not $conflict
        if ($complete) { foreach ($n in 1..$totals[0]) { if (-not $parts.ContainsKey($n)) { $complete=$false } } }
        [pscustomobject]@{ key=$group.Name; role=$group.Group[0].role; complete=$complete; conflictingFragments=$conflict
            expectedTotals=$totals; receivedNumbers=@($parts.Keys | Sort-Object); path=$group.Group[0].data['Path']
            scriptBlockId=$group.Group[0].data['ScriptBlockId']; text=(($parts.Keys | Sort-Object | ForEach-Object { $parts[$_] }) -join '') }
    }
}

function Test-JournalTargetLink {
    param($Event, [string]$Address, [string]$AepId)
    # Only explicit structured values link a device. A friendly name or arbitrary script text does not.
    $hex = $Address -replace ':',''
    foreach ($key in $Event.data.Keys) {
        if ($key -notmatch '^(?:BluetoothAddress|DeviceAddress|Address|DeviceId|DeviceInstanceId|DeviceInstancePath|InstanceId|InstancePath|AepId|EndpointId)$') { continue }
        $value = [string]$Event.data[$key]
        if ($AepId -and $value -eq $AepId) { return $true }
        if (($value -replace '[:-]','') -eq $hex) { return $true }
        if ($value -match ('(?i)(?:^|[^a-z0-9])DEV_' + [regex]::Escape($hex) + '(?:[^0-9a-f]|$)')) { return $true }
    }
    return $false
}

function Get-JournalClassification {
    param([int]$Count, [object[]]$Channels, [bool]$Incomplete=$false)
    if ($Count -gt 0) { return 'observed' }
    if ($Incomplete -or $Channels.Count -eq 0) { return 'unavailable/inconclusive' }
    foreach ($channel in $Channels) {
        if (-not $channel.before.available -or -not $channel.before.enabled -or $channel.before.error -or
            $channel.errors.Count -gt 0 -or $channel.gaps.Count -gt 0 -or
            ($null -ne $channel.after -and ($channel.after.error -or -not $channel.after.available -or $channel.after.newest -gt $channel.cursor))) { return 'unavailable/inconclusive' }
    }
    return 'not observed in the captured window'
}

function Get-JournalSummary {
    param($Run, $Coverage, [object[]]$Events, [object[]]$Processes, [string]$StartUtc, [string]$EndUtc, $ApiResult)
    Set-JournalProcessGuids $Events $Processes
    $measured = @($Events | Where-Object {
        [DateTime]::Parse($_.utc) -ge [DateTime]::Parse($StartUtc) -and [DateTime]::Parse($_.utc) -le [DateTime]::Parse($EndUtc)
    })
    foreach ($evt in $measured) { $evt | Add-Member role (Get-JournalRole $evt $Processes) -Force }
    $blocks = @(Join-JournalScriptBlocks $measured)
    $subjectBlocks = @($blocks | Where-Object { $_.role -eq 'subject' })
    $sysmon = @($measured | Where-Object { $_.provider -eq 'Microsoft-Windows-Sysmon' -and $_.eventId -eq 1 -and $_.role -eq 'subject' })
    $deviceEvents = @($measured | Where-Object { $_.provider -match 'Bluetooth|BTH|UserPnp|Kernel-PnP|DeviceSetupManager' })
    $linked = @($deviceEvents | Where-Object { Test-JournalTargetLink $_ $Run.target.address $Run.target.aepId })
    $psChannels = @($Coverage.channels | Where-Object { $_.before.name -eq 'Microsoft-Windows-PowerShell/Operational' })
    $smChannels = @($Coverage.channels | Where-Object { $_.before.name -eq 'Microsoft-Windows-Sysmon/Operational' })
    $devChannels = @($Coverage.channels | Where-Object { $_.before.name -match 'Bluetooth|BTH|UserPnp|^System$' })
    $subjectUncertain = @($Processes | Where-Object { $_.role -eq 'subject' -and $_.lifetimeUncertain }).Count -gt 0
    $rows = @(
        [pscustomobject]@{ signal='Subject PowerShell 4104'; classification=(Get-JournalClassification $subjectBlocks.Count $psChannels $subjectUncertain); count=$subjectBlocks.Count },
        [pscustomobject]@{ signal='Subject Sysmon process creation'; classification=(Get-JournalClassification $sysmon.Count $smChannels); count=$sysmon.Count },
        [pscustomobject]@{ signal='Explicit target device events'; classification=(Get-JournalClassification $linked.Count $devChannels); count=$linked.Count },
        [pscustomobject]@{ signal='Temporal device candidates (not target proof)'; classification=(Get-JournalClassification ($deviceEvents.Count-$linked.Count) $devChannels); count=($deviceEvents.Count-$linked.Count) }
    )
    [pscustomobject]@{ schemaVersion=1; runId=$Run.runId; mode=$Run.mode; target=$Run.target; host=$Run.host
        measuredStartUtc=$StartUtc; capturedThroughUtc=$EndUtc; processes=$Processes; apiResult=$ApiResult; rows=$rows
        scriptBlocks=$blocks; incompleteScriptBlocks=@($blocks | Where-Object { -not $_.complete }).Count
        eventAttribution=@($measured | ForEach-Object { @{ channel=$_.channel; recordId=$_.recordId; utc=$_.utc; role=$_.role
            targetLinked=(Test-JournalTargetLink $_ $Run.target.address $Run.target.aepId) } })
        sysmonImageHashes=@($sysmon | ForEach-Object { @{ processGuid=$_.data['ProcessGuid']; image=$_.data['Image']; hashes=$_.data['Hashes'] } })
        coverage=$Coverage; limitations=@('Local capture does not establish Wazuh ingestion or alerts.',
            'An enabled PowerShell channel does not prove script-block logging is enabled; 4104 does not prove each logged statement executed.',
            'Capture is a finite polling window, including a ten-second tail. Device events without an explicit target link are temporal candidates.',
            "Wazuh preflight: $($Run.wazuhState). Sysmon channel availability is preserved in coverage.",
            "Processes with unresolved lifetime: $(@($Processes | Where-Object { $_.lifetimeUncertain }).Count). Non-Sysmon attribution for those processes is inconclusive.") }
}

function Read-JournalEvents {
    param([string]$Path)
    foreach ($line in [IO.File]::ReadLines($Path)) {
        if (-not $line.Trim()) { continue }
        $evt=$line | ConvertFrom-Json
        $data=@{}; foreach ($property in $evt.data.PSObject.Properties) { $data[$property.Name]=$property.Value }
        $evt.data=$data
        $evt
    }
}

function Compare-BleJournals {
    param([string]$ScriptedRun, [string]$ManualRun)
    $scripted = Get-Content -LiteralPath (Join-Path $ScriptedRun 'summary.json') -Raw | ConvertFrom-Json
    $manual = Get-Content -LiteralPath (Join-Path $ManualRun 'summary.json') -Raw | ConvertFrom-Json
    if ($scripted.mode -ne 'Scripted' -or $manual.mode -ne 'Manual') { throw 'Compare requires one Scripted and one Manual summary.' }
    if ($scripted.target.address -ne $manual.target.address -or $scripted.host.name -ne $manual.host.name) { throw 'Runs must use the same exact address and host.' }
    '| Signal | Scripted | Manual |'
    '|---|---|---|'
    foreach ($row in $scripted.rows) {
        $other = $manual.rows | Where-Object { $_.signal -eq $row.signal }
        "| $($row.signal) | $($row.classification) ($($row.count)) | $($other.classification) ($($other.count)) |"
    }
    ''
    "Scripted API outcome: $($scripted.apiResult.outcome). Manual postcheck outcome: $($manual.apiResult.outcome)."
    "Incomplete 4104 records: scripted=$($scripted.incompleteScriptBlocks), manual=$($manual.incompleteScriptBlocks)."
    @($scripted.limitations + $manual.limitations | Sort-Object -Unique)
    foreach ($summary in @($scripted,$manual)) {
        foreach ($channel in $summary.coverage.channels) {
            if (-not $channel.before.available -or -not $channel.before.enabled -or $channel.before.error -or $channel.errors.Count -or $channel.gaps.Count) {
                "$($summary.mode): $($channel.before.name) unavailable/inconclusive; enabled=$($channel.before.enabled); $($channel.before.error); errors=$($channel.errors.Count); gaps=$($channel.gaps -join ', ')"
            }
        }
    }
}
Export-ModuleMember -Function Start-JournalCapture,Get-JournalProcess,Update-JournalLifetimes,Get-JournalSummary,Read-JournalEvents,Compare-BleJournals
