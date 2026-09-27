Import-Module (Join-Path $PSScriptRoot '../scripts/BlePairingTelemetry.psm1') -Force
InModuleScope BlePairingTelemetry {
    function New-TelemetryProcess([string]$Role='subject', [int]$ProcessId=42, [string]$Guid='guid-real') {
        [pscustomobject]@{ role=$Role; processId=$ProcessId; processStartUtc='2026-09-27T14:00:00.1230000Z'; endUtc='2026-09-27T14:00:10Z'
            image='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'; processGuid=$Guid
            lifetimeUncertain=$false; observedUntilUtc='2026-09-27T14:00:11Z' }
    }
    function New-TelemetryEvent([string]$Provider='Microsoft-Windows-PowerShell', [int]$EventId=4104, [int]$ProcessId=42) {
        [pscustomobject]@{ provider=$Provider; eventId=$EventId; recordId=99; computer='WINSTONDESKTOP'; role='subject'
            utc='2026-09-27T14:00:01Z'; systemProcessId=$ProcessId; data=@{}; channel='test' }
    }
    function New-TelemetryChannel {
        $meta=[pscustomobject]@{ name='test'; available=$true; enabled=$true; error=$null; oldest=1; newest=100 }
        [pscustomobject]@{ before=$meta; after=$meta; cursor=100; errors=@(); gaps=@() }
    }
    Describe 'Process attribution' {
        It 'does not mistake observer script text for subject execution' {
            $evt=New-TelemetryEvent -ProcessId 17; $evt.data=@{ ScriptBlockText='Invoke-BleAutoPair.ps1' }
            Get-JournalRole $evt @((New-TelemetryProcess 'observer' 17),(New-TelemetryProcess)) | Should Be 'observer'
        }
        It 'uses Sysmon EventData PID and GUID, not System execution PID' {
            $evt=New-TelemetryEvent 'Microsoft-Windows-Sysmon' 1 999
            $evt.data=@{ ProcessId='42'; ProcessGuid='guid-real' }
            Get-JournalRole $evt @((New-TelemetryProcess)) | Should Be 'subject'
            $evt.data.ProcessGuid='recycled-guid'
            Get-JournalRole $evt @((New-TelemetryProcess)) | Should Be 'unattributed'
        }
        It 'refuses a reused PID after the known process exit' {
            $evt=New-TelemetryEvent; $evt.utc='2026-09-27T14:00:20Z'
            Get-JournalRole $evt @((New-TelemetryProcess)) | Should Be 'unattributed'
        }
        It 'does not attribute PowerShell to a recycled Settings PID or unresolved lifetime' {
            $evt=New-TelemetryEvent; $proc=New-TelemetryProcess
            $proc.image='C:\Windows\ImmersiveControlPanel\SystemSettings.exe'; $proc.endUtc=$null
            Get-JournalRole $evt @($proc) | Should Be 'unattributed'
            $proc=New-TelemetryProcess; $proc.lifetimeUncertain=$true
            Get-JournalRole $evt @($proc) | Should Be 'unattributed'
        }
        It 'parses timezone-free Sysmon creation time as UTC and binds only the exact lifetime' {
            $proc=New-TelemetryProcess; $proc.processGuid=$null
            $evt=New-TelemetryEvent 'Microsoft-Windows-Sysmon' 1
            $evt.data=@{ ProcessId='42'; ProcessGuid='guid-real'; Image=$proc.image; UtcTime='2026-09-27 14:00:00.123' }
            Set-JournalProcessGuids @($evt) @($proc)
            $proc.processGuid | Should Be 'guid-real'
            $proc.processGuid=$null; $evt.data.UtcTime='2026-09-27 14:00:01.123'
            Set-JournalProcessGuids @($evt) @($proc)
            $proc.processGuid | Should BeNullOrEmpty
        }
        It 'leaves GUID unknown when the subject creation event is absent' {
            $proc=New-TelemetryProcess; $proc.processGuid=$null
            Set-JournalProcessGuids @() @($proc)
            $proc.processGuid | Should BeNullOrEmpty
        }
    }
    Describe '4104 reconstruction' {
        BeforeEach {
            $script:first=New-TelemetryEvent; $script:second=New-TelemetryEvent
            $script:first.data=@{ ScriptBlockId='block'; MessageNumber='1'; MessageTotal='2'; ScriptBlockText='hello '; Path='subject.ps1' }
            $script:second.data=@{ ScriptBlockId='block'; MessageNumber='2'; MessageTotal='2'; ScriptBlockText='world'; Path='subject.ps1' }
        }
        It 'orders and reassembles all fragments' {
            $block=@(Join-JournalScriptBlocks @($script:second,$script:first))[0]
            $block.complete | Should Be $true
            $block.text | Should Be 'hello world'
        }
        It 'flags missing fragments' { @(Join-JournalScriptBlocks @($script:second))[0].complete | Should Be $false }
        It 'flags inconsistent totals' {
            $script:second.data.MessageTotal='3'
            @(Join-JournalScriptBlocks @($script:first,$script:second))[0].complete | Should Be $false
        }
        It 'deduplicates identical fragments and rejects conflicting duplicates' {
            @(Join-JournalScriptBlocks @($script:first,$script:first,$script:second))[0].complete | Should Be $true
            $third=New-TelemetryEvent; $third.data=@{ ScriptBlockId='block'; MessageNumber='1'; MessageTotal='2'; ScriptBlockText='WRONG'; Path='subject.ps1' }
            @(Join-JournalScriptBlocks @($script:first,$third,$script:second))[0].complete | Should Be $false
        }
        It 'keeps observer fragments separate from subject fragments' {
            $script:second.role='observer'
            $blocks=@(Join-JournalScriptBlocks @($script:first,$script:second))
            $blocks.Count | Should Be 2
            @($blocks | Where-Object { $_.complete }).Count | Should Be 0
        }
    }
    Describe 'Coverage and explicit target links' {
        It 'distinguishes empty healthy capture from unavailable channels' {
            $channel=New-TelemetryChannel
            Get-JournalClassification 0 @($channel) | Should Be 'not observed in the captured window'
            $channel.before.available=$false
            Get-JournalClassification 0 @($channel) | Should Be 'unavailable/inconclusive'
            $channel=New-TelemetryChannel; $channel.before.enabled=$false
            Get-JournalClassification 0 @($channel) | Should Be 'unavailable/inconclusive'
            $channel=New-TelemetryChannel; $channel.errors=@('Access denied')
            Get-JournalClassification 0 @($channel) | Should Be 'unavailable/inconclusive'
        }
        It 'retains observed evidence even if channel coverage has gaps' {
            $channel=New-TelemetryChannel; $channel.gaps=@('rollover')
            Get-JournalClassification 1 @($channel) | Should Be 'observed'
            Get-JournalClassification 0 @($channel) | Should Be 'unavailable/inconclusive'
        }
        It 'detects reset, rollover, and unread final tail' {
            $before=(New-TelemetryChannel).before; $after=(New-TelemetryChannel).after
            $after.newest=99
            Get-JournalGap $before $after 100 | Should Match 'reset'
            $after.newest=200; $after.oldest=150
            Get-JournalGap $before $after 100 | Should Match 'Rollover'
            $channel=New-TelemetryChannel; $channel.after=(New-TelemetryChannel).after; $channel.after.newest=101
            Get-JournalClassification 0 @($channel) | Should Be 'unavailable/inconclusive'
        }
        It 'links explicit address or AEP identity and excludes friendly-name matches' {
            $evt=New-TelemetryEvent 'Bluetooth' 1
            $evt.data=@{ DeviceAddress='AA:BB:CC:DD:EE:FF' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $true
            $evt.data=@{ DeviceId='aep-target' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $true
            $evt.data=@{ DeviceName='DEV_AABBCCDDEEFF' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $false
            $evt.data=@{ DeviceId='BTHLE\DEV_11AABBCCDDEEFF\instance' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $false
            $evt.data=@{ DeviceId='BTHLE\DEV_AABBCCDDEEFF\instance' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $true
            $evt.data=@{ DeviceAddress='11:22:33:44:55:66'; DeviceName='S3-HID-KM-v7' }
            Test-JournalTargetLink $evt 'AA:BB:CC:DD:EE:FF' 'aep-target' | Should Be $false
        }
        It 'keeps unrelated Bluetooth events as temporal candidates in summary' {
            $evt=New-TelemetryEvent 'Microsoft-Windows-Bluetooth-Test' 1
            $evt.data=@{ DeviceAddress='11:22:33:44:55:66' }
            $run=@{ runId='test'; mode='Scripted'; target=@{ address='AA:BB:CC:DD:EE:FF'; aepId='target' }; host=@{name='WINSTONDESKTOP'}; wazuhState='Stopped' }
            $coverage=@{ channels=@((New-TelemetryChannel)) }
            $summary=Get-JournalSummary $run $coverage @($evt) @((New-TelemetryProcess)) '2026-09-27T14:00:00Z' '2026-09-27T14:00:11Z' @{outcome='failed'}
            @($summary.rows | Where-Object { $_.signal -eq 'Explicit target device events' })[0].count | Should Be 0
            @($summary.rows | Where-Object { $_.signal -like 'Temporal*' })[0].count | Should Be 1
            $summary.limitations -join ' ' | Should Match 'Wazuh preflight: Stopped'
        }
        It 'classifies uncertain subject lifetime as inconclusive, without observer contamination' {
            $run=@{ runId='test'; mode='Manual'; target=@{address='AA:BB:CC:DD:EE:FF';aepId='target'};host=@{name='WINSTONDESKTOP'};wazuhState='Stopped' }
            $channel=New-TelemetryChannel; $channel.before.name='Microsoft-Windows-PowerShell/Operational'
            $coverage=@{channels=@($channel)}
            $proc=New-TelemetryProcess; $proc.lifetimeUncertain=$true
            $summary=Get-JournalSummary $run $coverage @((New-TelemetryEvent)) @($proc) '2026-09-27T14:00:00Z' '2026-09-27T14:00:11Z' @{outcome='failed'}
            $summary.rows[0].classification | Should Be 'unavailable/inconclusive'
            $proc.role='observer'
            $summary=Get-JournalSummary $run $coverage @((New-TelemetryEvent)) @($proc) '2026-09-27T14:00:00Z' '2026-09-27T14:00:11Z' @{outcome='failed'}
            $summary.rows[0].classification | Should Be 'not observed in the captured window'
        }
    }
    Describe 'Structured Windows event parsing' {
        It 'keeps System PID separate from Sysmon EventData PID and raw XML' {
            $record=[pscustomobject]@{ LogName='Sysmon'; ProviderName='Microsoft-Windows-Sysmon'; Id=1; RecordId=22; TimeCreated=[DateTime]::UtcNow }
            $record | Add-Member ScriptMethod ToXml { '<Event><System><Computer>host</Computer><Execution ProcessID="999" /></System><EventData><Data Name="ProcessId">42</Data><Data Name="ProcessGuid">guid</Data></EventData></Event>' }
            $event=ConvertFrom-JournalEvent $record
            $event.systemProcessId | Should Be '999'
            $event.data.ProcessId | Should Be '42'
            $event.rawXml | Should Match 'ProcessGuid'
        }
    }
}
