Import-Module (Join-Path $PSScriptRoot '../scripts/BlePairing.psm1') -Force
InModuleScope BlePairing {
    function New-TestDevice([string]$Address='AA:BB:CC:DD:EE:FF', [bool]$Paired=$false, [string]$Id='aep-1') {
        [pscustomobject]@{ Id=$Id; Name='same-name'; Kind='AssociationEndpoint'; Properties=@{ 'System.Devices.Aep.DeviceAddress'=$Address }
            Pairing=[pscustomobject]@{ IsPaired=$Paired; CanPair=$true } }
    }
    function New-TestOperation([string]$Status='Paired', [bool]$Terminal=$true, [bool]$Timeout=$false) {
        [pscustomobject]@{ method='Test'; startedUtc='2026-09-27T00:00:00Z'; endedUtc='2026-09-27T00:00:01Z'; elapsedMs=1000
            nativeStatus=$Status; exception=$null; timedOut=$Timeout; cancellationRequested=$Timeout; cancellationError=$null
            terminal=$Terminal; terminalObservedUtc=$null; task=$null; value=$null; operation=$null }
    }
    Describe 'Address validation and action boundaries' {
        It 'normalizes twelve digits, colon and hyphen forms' {
            ConvertTo-BleAddress 'aabbccddeeff' | Should Be 'AA:BB:CC:DD:EE:FF'
            ConvertTo-BleAddress 'aa:bb:cc:dd:ee:ff' | Should Be 'AA:BB:CC:DD:EE:FF'
            ConvertTo-BleAddress 'aa-bb-cc-dd-ee-ff' | Should Be 'AA:BB:CC:DD:EE:FF'
        }
        It 'rejects malformed, overlong, partial and mixed separators' {
            foreach ($bad in @('', 'abcdef', 'AA:BB:CC:DD:EE:FF:00', 'AA:BB-CC:DD:EE:FF', 'GG:00:00:00:00:00','0xAABBCCDDEEFF')) {
                { ConvertTo-BleAddress $bad } | Should Throw
            }
        }
        It 'requires explicit address and rejects action/discovery combination before initialization' {
            Mock Initialize-BleRuntime { throw 'should not initialize' }
            (Invoke-BlePairing -Pair).exitCode | Should Be 2
            (Invoke-BlePairing -BleAddress aabbccddeeff -DiscoverOnly -Pair).exitCode | Should Be 2
            Assert-MockCalled -Scope It Initialize-BleRuntime -Times 0
        }
        It 'selects by exact address despite duplicate names' {
            $devices=@((New-TestDevice '11:22:33:44:55:66' $false 'wrong'),(New-TestDevice))
            (Select-BleExactDevice $devices 'AA:BB:CC:DD:EE:FF').Id | Should Be 'aep-1'
        }
        It 'narrows the AQS query to a validated address, never a name' {
            $selector=Get-BleAepSelector '7c4fad215289'
            $selector | Should Match 'System.Devices.Aep.DeviceAddress:="7C:4F:AD:21:52:89"'
            $selector | Should Not Match 'Name'
            { Get-BleAepSelector 'bad" OR Name:="anything' } | Should Throw
            Get-BleAepSelector | Should Not Match 'DeviceAddress'
        }
        It 'refuses duplicate exact addresses and ignores missing address properties' {
            { Select-BleExactDevice @((New-TestDevice),(New-TestDevice)) 'AA:BB:CC:DD:EE:FF' } | Should Throw
            $missing=New-TestDevice; $missing.Properties=@{}
            (Select-BleExactDevice @($missing) 'AA:BB:CC:DD:EE:FF') | Should BeNullOrEmpty
            (ConvertTo-BleDeviceRecord $missing).isConnectable | Should BeNullOrEmpty
        }
        It 'resolves relative result paths against the PowerShell working directory and preserves prior evidence' {
            Push-Location $TestDrive
            try {
                Write-BleJson @{ okay=$true } 'relative.json'
                Test-Path -LiteralPath (Join-Path $TestDrive 'relative.json') | Should Be $true
                { Write-BleJson @{} 'relative.json' } | Should Throw
            } finally { Pop-Location }
        }
    }
    Describe 'Pairing state machine using mocked native wrappers' {
        BeforeEach {
            Mock Initialize-BleRuntime {}
            $script:discoveryCount=0
            Mock Get-BleDiscovery {
                $script:discoveryCount++
                [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' ($script:discoveryCount -gt 1))) }
            }
            Mock Invoke-BleMutation { New-TestOperation }
        }
        It 'defaults an address to pairing and verifies a fresh exact target' {
            $result=Invoke-BlePairing -BleAddress aabbccddeeff
            $result.exitCode | Should Be 0
            $result.stateAfter.isPaired | Should Be $true
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 1 -ParameterFilter { $Action -eq 'Pair' }
            Assert-MockCalled -Scope It Get-BleDiscovery -Times 2 -ParameterFilter { $Address -eq 'AA:BB:CC:DD:EE:FF' }
        }
        It 'does no mutation during discovery' {
            (Invoke-BlePairing -BleAddress aabbccddeeff -DiscoverOnly).exitCode | Should Be 0
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 0
        }
        It 'postchecks an already-paired target' {
            Mock Get-BleDiscovery { [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' $true)) } }
            (Invoke-BlePairing -BleAddress aabbccddeeff).exitCode | Should Be 0
            Assert-MockCalled -Scope It Get-BleDiscovery -Times 2
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 0
        }
        It 'does not re-pair after failed unpair' {
            Mock Get-BleDiscovery { [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' $true)) } }
            Mock Invoke-BleMutation { New-TestOperation 'Failed' }
            (Invoke-BlePairing -BleAddress aabbccddeeff -Unpair -Pair).exitCode | Should Be 1
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 1 -ParameterFilter { $Action -eq 'Unpair' }
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 0 -ParameterFilter { $Action -eq 'Pair' }
        }
        It 'verifies Windows unpaired state before re-pairing' {
            Mock Get-BleDiscovery {
                $script:discoveryCount++
                [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' ($script:discoveryCount -ne 2))) }
            }
            Mock Invoke-BleMutation { if ($Action -eq 'Unpair') { New-TestOperation 'Unpaired' } else { New-TestOperation 'Paired' } }
            (Invoke-BlePairing -BleAddress aabbccddeeff -Unpair -Pair).exitCode | Should Be 0
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 2
            Assert-MockCalled -Scope It Get-BleDiscovery -Times 3
        }
        It 'keeps a timed-out pending mutation unknown despite apparent paired state' {
            Mock Invoke-BleMutation { New-TestOperation '' $false $true }
            (Invoke-BlePairing -BleAddress aabbccddeeff).exitCode | Should Be 3
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 1
        }
        It 'permits reconciled late completion only when terminal and exact state agree' {
            Mock Invoke-BleMutation { New-TestOperation 'Paired' $true $true }
            $result=Invoke-BlePairing -BleAddress aabbccddeeff
            $result.exitCode | Should Be 0
            @($result.operations | Where-Object { $_.timedOut }).Count | Should Be 1
        }
        It 'preserves native evidence and HRESULT when postcheck throws' {
            Mock Get-BleDiscovery {
                $script:discoveryCount++
                if ($script:discoveryCount -gt 1) { throw 'postcheck failed' }
                [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice)) }
            }
            $result=Invoke-BlePairing -BleAddress aabbccddeeff
            $result.exitCode | Should Be 3
            $result.operations.Count | Should Be 2
            $result.exception.hresult | Should Not BeNullOrEmpty
        }
        It 'reconciles a task that actually completes during the postcheck' {
            $script:completion=New-Object 'System.Threading.Tasks.TaskCompletionSource[object]'
            Mock Invoke-BleMutation {
                $record=New-TestOperation '' $false $true
                $record.task=$script:completion.Task
                $record
            }
            Mock Get-BleDiscovery {
                $script:discoveryCount++
                if ($script:discoveryCount -gt 1) { $script:completion.SetResult([pscustomobject]@{Status='Paired'}) }
                [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' ($script:discoveryCount -gt 1))) }
            }
            $result=Invoke-BlePairing -BleAddress aabbccddeeff
            $result.exitCode | Should Be 0
            $late=@($result.operations | Where-Object { $_.timedOut })[0]
            $late.nativeStatus | Should Be 'Paired'
            $late.terminalObservedUtc | Should Not BeNullOrEmpty
        }
        It 'reports consent cancellation as failure after unpaired postcheck' {
            Mock Invoke-BleMutation { New-TestOperation 'PairingCanceled' }
            Mock Get-BleDiscovery { [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice)) } }
            (Invoke-BlePairing -BleAddress aabbccddeeff).exitCode | Should Be 1
        }
        It 'treats OperationAlreadyInProgress as unknown' {
            Mock Invoke-BleMutation { New-TestOperation 'OperationAlreadyInProgress' }
            Mock Get-BleDiscovery { [pscustomobject]@{ operation=(New-TestOperation); devices=@((New-TestDevice)) } }
            (Invoke-BlePairing -BleAddress aabbccddeeff).exitCode | Should Be 3
        }
        It 'does not treat disappearing target as verified unpairing' {
            Mock Get-BleDiscovery {
                $script:discoveryCount++
                $devices=@(); if ($script:discoveryCount -eq 1) { $devices=@((New-TestDevice 'AA:BB:CC:DD:EE:FF' $true)) }
                [pscustomobject]@{ operation=(New-TestOperation); devices=$devices }
            }
            Mock Invoke-BleMutation { New-TestOperation 'Unpaired' }
            (Invoke-BlePairing -BleAddress aabbccddeeff -Unpair -Pair).exitCode | Should Be 3
            Assert-MockCalled -Scope It Invoke-BleMutation -Times 1
        }
    }
    Describe 'Bounded operation wrappers' {
        It 'requests cancellation when the native wait times out' {
            Mock ConvertTo-BleTask { [pscustomobject]@{ IsCompleted=$false } }
            Mock Wait-BleTask { $false }
            Mock Stop-BleOperation {}
            $op=Invoke-BleNativeOperation -Start { 'operation' } -ResultType ([string]) -TimeoutSeconds 120 -Method PairAsync
            $op.timedOut | Should Be $true
            $op.cancellationRequested | Should Be $true
            $op.terminal | Should Be $false
            Assert-MockCalled -Scope It Stop-BleOperation -Times 1
            Assert-MockCalled -Scope It Wait-BleTask -ParameterFilter { $Milliseconds -le 120000 -and $Milliseconds -ge 0 }
        }
        It 'suppresses explicit null output from cancellation and returns one timeout record' {
            Mock ConvertTo-BleTask { [pscustomobject]@{ IsCompleted=$false } }
            Mock Wait-BleTask { $false }
            Mock Stop-BleOperation { $null }
            $records=@(Invoke-BleNativeOperation -Start { 'operation' } -ResultType ([string]) -TimeoutSeconds 30 -Method FindAllAsync)
            $records.Count | Should Be 1
            ($records[0].PSObject.Properties.Name -contains 'value') | Should Be $true
            $records[0].timedOut | Should Be $true
        }
    }
    Describe 'Actual non-BLE WinRT projection' {
        It 'bridges and cancels actual WinRT using a local existing file, without BLE' {
            Add-Type -AssemblyName System.Runtime.WindowsRuntime
            $null=[Windows.Foundation.IAsyncInfo,Windows.Foundation,ContentType=WindowsRuntime]
            $null=[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
            $file=(Get-Module BlePairing).Path
            $operation=[Windows.Storage.StorageFile]::GetFileFromPathAsync($file)
            $task=ConvertTo-BleTask $operation ([Windows.Storage.StorageFile])
            $task.Wait(5000) | Should Be $true
            $task.Result.Path | Should Be $file
            { Stop-BleOperation $operation } | Should Not Throw
            @(Stop-BleOperation $operation).Count | Should Be 0
        }
    }
}
