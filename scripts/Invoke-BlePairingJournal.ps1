<#
.SYNOPSIS
Record Scripted or Manual pairing and compare local telemetry, without configuring logging.
.EXAMPLE
 .\Invoke-BlePairingJournal.ps1 -Mode Scripted -BleAddress AA:BB:CC:DD:EE:FF -SetupUnpair
.EXAMPLE
 .\Invoke-BlePairingJournal.ps1 -Mode Manual -BleAddress AA:BB:CC:DD:EE:FF -SetupUnpair
.EXAMPLE
 .\Invoke-BlePairingJournal.ps1 -Mode Compare -ScriptedRun build\pairing-runs\... -ManualRun build\pairing-runs\...
#>
[CmdletBinding()]
param([ValidateSet('Scripted','Manual','Compare')][string]$Mode,
    [string]$BleAddress, [switch]$SetupUnpair, [string]$ScriptedRun, [string]$ManualRun)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'BlePairing.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'BlePairingTelemetry.psm1') -Force
if (-not $Mode) { Write-Host 'Choose -Mode Scripted or Manual with -BleAddress, or Compare with -ScriptedRun and -ManualRun.'; exit 0 }
if ($Mode -eq 'Compare') {
    try { Compare-BleJournals $ScriptedRun $ManualRun; exit 0 } catch { Write-Warning $_; exit 2 }
}
$job=$null; $runDir=$null; $run=$null; $apiResult=$null; $exitCode=2; $measureStart=$null; $actionEnd=$null; $captureEnd=$null
try {
    $address=ConvertTo-BleAddress $BleAddress
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.ToString() -notlike '5.1.*' -or
        $env:COMPUTERNAME -ne 'WINSTONDESKTOP' -or -not [Environment]::UserInteractive -or
        (Get-Process -Id $PID).SessionId -eq 0 -or (Get-Variable PSSenderInfo -ErrorAction SilentlyContinue)) {
        throw 'Run in a local interactive Windows PowerShell 5.1 session on WINSTONDESKTOP.'
    }
    $runId=([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N'))
    $runDir=Join-Path (Split-Path $PSScriptRoot -Parent) ('build\pairing-runs\' + $runId)
    $null=New-Item -ItemType Directory -Path $runDir
    $processes=@(Get-JournalProcess (Get-Process -Id $PID) 'observer')
    $setup=@()
    if ($SetupUnpair) {
        Write-Host 'Setup only: unpairing the exact Windows target before the measured interval.'
        $unpair=Invoke-BlePairing -BleAddress $address -Unpair
        $setup += $unpair
        Write-BleJson $unpair (Join-Path $runDir 'setup-unpair.json')
        if ($unpair.exitCode -ne 0) { $exitCode=$unpair.exitCode; throw 'Setup unpair was not verified; no pairing attempt launched.' }
    }
    $discovery=Invoke-BlePairing -BleAddress $address -DiscoverOnly
    $setup += $discovery
    Write-BleJson $discovery (Join-Path $runDir 'setup-discovery.json')
    if ($discovery.exitCode -ne 0) { $exitCode=$discovery.exitCode; throw 'Discovery-only precondition failed; no pairing attempt launched.' }
    $target=@($discovery.devices | Where-Object { $_.address -eq $address })[0]
    if ($target.isPaired) { throw 'Target is already paired. Perform a separate unpair setup or explicitly use -SetupUnpair for a comparable attempt.' }
    $wazuh='unavailable'
    try { $wazuh=[string](Get-Service -Name WazuhSvc -ErrorAction Stop).Status } catch { $wazuh=$_.ToString() }
    $version=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $hashes=@{}
    foreach ($file in @('Invoke-BleAutoPair.ps1','BlePairing.psm1','Invoke-BlePairingJournal.ps1','BlePairingTelemetry.psm1')) {
        $hashes[$file]=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file) -Algorithm SHA256).Hash
    }
    $policy=@()
    foreach ($key in @('HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging','HKCU:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging')) {
        try { $policy += @{ path=$key; value=(Get-ItemProperty -LiteralPath $key -ErrorAction Stop | Select-Object EnableScriptBlockLogging,EnableScriptBlockInvocationLogging); error=$null } }
        catch { $policy += @{ path=$key; value=$null; error=$_.ToString() } }
    }
    $run=[pscustomobject]@{ schemaVersion=1; runId=$runId; mode=$Mode; createdUtc=[DateTime]::UtcNow.ToString('o')
        host=@{ name=$env:COMPUTERNAME; build=$version.CurrentBuildNumber; ubr=$version.UBR; displayVersion=$version.DisplayVersion }
        session=@{ id=(Get-Process -Id $PID).SessionId; powerShell=$PSVersionTable.PSVersion.ToString(); interactive=[Environment]::UserInteractive }
        target=$target; scriptSha256=$hashes; executableHashesLocation='summary.json processes and sysmonImageHashes'
        wazuhState=$wazuh; loggingPolicy=$policy; setup=$setup; setupRole='observer executing setup, outside measured capture'
        initialProcesses=$processes }
    Write-BleJson $run (Join-Path $runDir 'run.json')
    $module=Join-Path $PSScriptRoot 'BlePairingTelemetry.psm1'
    $job=Start-Job -ScriptBlock { param($ModulePath,$Directory); Import-Module $ModulePath; Start-JournalCapture $Directory } -ArgumentList $module,$runDir
    $readyPath=Join-Path $runDir 'capture-ready.json'
    $wait=[Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath $readyPath)) {
        if ($job.State -in @('Failed','Completed','Stopped') -or $wait.Elapsed.TotalSeconds -gt 30) { throw 'Observer did not become ready; no pairing process launched.' }
        Start-Sleep -Milliseconds 100
    }
    $ready=Get-Content -LiteralPath $readyPath -Raw | ConvertFrom-Json
    $processes += Get-JournalProcess (Get-Process -Id $ready.processId) 'observer'
    if ($Mode -eq 'Scripted') {
        $subjectPath=Join-Path $PSScriptRoot 'Invoke-BleAutoPair.ps1'
        $resultPath=Join-Path $runDir 'subject-result.json'
        $measureStart=[DateTime]::UtcNow.ToString('o')
        $subject=Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList @(
            '-NoProfile','-File',('"'+$subjectPath+'"'),'-BleAddress',$address,'-Pair','-ResultPath',('"'+$resultPath+'"')) `
            -RedirectStandardOutput (Join-Path $runDir 'subject.stdout.txt') -RedirectStandardError (Join-Path $runDir 'subject.stderr.txt')
        # Retain the process handle while it is alive; PS 5.1 Start-Process may otherwise lose exit metadata.
        $null=$subject.Handle
        $identity=Get-JournalProcess $subject 'subject'; $processes += $identity
        Write-Host 'Pairing subject launched. Respond to any Windows consent UI. Native pairing is bounded to 120 seconds.'
        $deadline=[DateTime]::UtcNow.AddSeconds(210)
        while (-not $subject.HasExited -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 200; $subject.Refresh() }
        $actionEnd=[DateTime]::UtcNow.ToString('o')
        if ($subject.HasExited) {
            $identity | Add-Member exitObservedUtc $actionEnd
            $identity | Add-Member exitCode $subject.ExitCode
            if ($null -ne $subject.ExitTime) { $identity.endUtc=$subject.ExitTime.ToUniversalTime().ToString('o') }
            else { $identity.lifetimeUncertain=$true }
            if (Test-Path -LiteralPath $resultPath) { $apiResult=Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json; $exitCode=$apiResult.exitCode }
            else { $apiResult=@{ outcome='unknown'; exitCode=3; message='Subject exited without a result. Inspect stdout/stderr; do not retry automatically.' }; $exitCode=3 }
        } else {
            $apiResult=@{ outcome='unknown'; exitCode=3; message='Subject exceeded journal deadline; it remains running. No kill or retry attempted.' }; $exitCode=3
        }
    } else {
        Write-Host 'Open Windows Settings > Bluetooth & devices > Add device. Verify the target identified by serial i and discovery; leave it unpaired until the start marker.'
        $null=Read-Host 'Press Enter immediately before starting the Settings pairing action'
        $measureStart=[DateTime]::UtcNow.ToString('o')
        $processes += @(Get-Process -Name SystemSettings -ErrorAction SilentlyContinue | ForEach-Object { Get-JournalProcess $_ 'subject' })
        $operatorResult=Read-Host 'After Settings reports completion/failure, enter the displayed outcome and press Enter'
        $actionEnd=[DateTime]::UtcNow.ToString('o')
        $processes += @(Get-Process -Name SystemSettings -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $processes.processId } | ForEach-Object { Get-JournalProcess $_ 'subject' })
        Write-BleJson @{ startUtc=$measureStart; completionUtc=$actionEnd; operatorText=$operatorResult; role='manual operator marker, not native API evidence' } (Join-Path $runDir 'manual-markers.json')
    }
    # The collector runs independently while the operator responds and throughout the tail.
    Start-Sleep -Seconds 10
    $captureEnd=[DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText((Join-Path $runDir 'capture-stop'), $captureEnd)
    $null=Wait-Job $job -Timeout 30
    if ($job.State -ne 'Completed') { throw 'Collector did not finish; retained run is incomplete. Do not infer absent telemetry.' }
    Receive-Job $job -ErrorAction Stop | Out-Null
    if ($Mode -eq 'Manual') {
        $post=Invoke-BlePairing -BleAddress $address -DiscoverOnly
        $confirmed=@($post.devices | Where-Object { $_.address -eq $address -and $_.isPaired }).Count -eq 1
        $apiResult=@{ outcome='unknown'; exitCode=3; discovery=$post; message='Manual outcome needs exact-device confirmation.' }
        if ($post.exitCode -eq 0 -and $confirmed) { $apiResult.outcome='succeeded'; $apiResult.exitCode=0; $apiResult.message='Fresh exact-device paired state confirmed after manual interval.' }
        elseif ($post.exitCode -eq 0) { $apiResult.outcome='failed'; $apiResult.exitCode=1; $apiResult.message='Exact device is not paired after manual interval.' }
        $exitCode=$apiResult.exitCode
        Write-BleJson $apiResult (Join-Path $runDir 'manual-postcheck.json')
    }
    $coverage=Get-Content -LiteralPath (Join-Path $runDir 'coverage.json') -Raw | ConvertFrom-Json
    $events=@(Read-JournalEvents (Join-Path $runDir 'events.jsonl'))
    Update-JournalLifetimes $processes
    $summary=Get-JournalSummary $run $coverage $events $processes $measureStart $captureEnd $apiResult
    $summary | Add-Member actionCompletedUtc $actionEnd
    Write-BleJson $summary (Join-Path $runDir 'summary.json')
    $summary.rows | Format-Table -AutoSize
    Write-Host "Run retained: $runDir"
    Write-Host "Pairing outcome: $($apiResult.outcome). Inspect serial q; mouse_sub=yes is still mandatory."
} catch {
    Write-Warning $_
    if ($measureStart) { $exitCode=3 }
    if ($runDir) {
        $failure=@{ outcome='unknown'; exitCode=$exitCode; error=$_.ToString(); stack=$_.ScriptStackTrace; location=$_.InvocationInfo.PositionMessage
            measuredStartUtc=$measureStart; actionCompletedUtc=$actionEnd
            limitation='Incomplete run. No absence or pairing-success inference is valid. Inspect retained files; do not retry uncertain mutation automatically.' }
        if (-not (Test-Path -LiteralPath (Join-Path $runDir 'summary.json'))) { Write-BleJson $failure (Join-Path $runDir 'summary.json') }
        if (-not (Test-Path -LiteralPath (Join-Path $runDir 'run.json'))) { Write-BleJson @{ runId=$runId; mode=$Mode; targetAddress=$address; setupFailure=$failure } (Join-Path $runDir 'run.json') }
        if (-not (Test-Path -LiteralPath (Join-Path $runDir 'events.jsonl'))) { [IO.File]::WriteAllText((Join-Path $runDir 'events.jsonl'),'') }
        Write-Host "Incomplete evidence retained: $runDir"
    }
} finally {
    if ($job -and $job.State -eq 'Running') {
        [IO.File]::WriteAllText((Join-Path $runDir 'capture-stop'), [DateTime]::UtcNow.ToString('o'))
        $null=Wait-Job $job -Timeout 10
    }
    if ($job -and $job.State -ne 'Running') { Remove-Job $job }
}
exit $exitCode
