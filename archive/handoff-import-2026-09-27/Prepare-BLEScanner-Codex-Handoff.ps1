param(
    [Parameter(Mandatory=$false)]
    [string]$Destination = (Join-Path (Get-Location) 'BLEScanner-Codex')
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$baseline = Join-Path $here 'BLEScanner_LOCKED_BASELINE_v7.ino'
$handoff  = Join-Path $here 'CODEX_CLI_HANDOFF_BLEScanner_v7.md'
$hashFile = Join-Path $here 'BLEScanner_LOCKED_BASELINE_v7.sha256.txt'

foreach ($f in @($baseline,$handoff,$hashFile)) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing required bundle file: $f" }
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null
Copy-Item -LiteralPath $baseline -Destination (Join-Path $Destination 'BLEScanner_LOCKED_BASELINE_v7.ino') -Force
Copy-Item -LiteralPath $handoff  -Destination (Join-Path $Destination 'CODEX_CLI_HANDOFF_BLEScanner_v7.md') -Force
Copy-Item -LiteralPath $hashFile -Destination (Join-Path $Destination 'BLEScanner_LOCKED_BASELINE_v7.sha256.txt') -Force

$actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $Destination 'BLEScanner_LOCKED_BASELINE_v7.ino')).Hash.ToLower()
$expected = '9f3c9099a50d7b83f9ff219d1a83767ffc319d4119f76e21b4088682a84914c6'

if ($actual -ne $expected) {
    throw "Baseline hash verification FAILED. Expected $expected but got $actual"
}

$work = Join-Path $Destination 'BLEScanner_WORKING_v7.ino'
if (-not (Test-Path -LiteralPath $work)) {
    Copy-Item -LiteralPath (Join-Path $Destination 'BLEScanner_LOCKED_BASELINE_v7.ino') -Destination $work
}

Write-Host ""
Write-Host "BLEScanner Codex handoff prepared." -ForegroundColor Green
Write-Host "Destination: $Destination"
Write-Host "Baseline SHA-256 verified: $actual"
Write-Host ""
Write-Host "LOCKED:  BLEScanner_LOCKED_BASELINE_v7.ino"
Write-Host "EDIT:    BLEScanner_WORKING_v7.ino"
Write-Host "READ:    CODEX_CLI_HANDOFF_BLEScanner_v7.md"
Write-Host ""
Write-Host "Start Codex from this directory and tell it to read CODEX_CLI_HANDOFF_BLEScanner_v7.md before changing anything."
