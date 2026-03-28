param(
    [Parameter(Mandatory = $true)]
    [string]$RunLabel,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$suiteRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runsRoot = Join-Path $suiteRoot "runs"
$runRoot = Join-Path $runsRoot $RunLabel

if ((Test-Path $runRoot) -and -not $Force) {
    throw "Run directory already exists: $runRoot. Re-run with -Force to replace it."
}

if (Test-Path $runRoot) {
    Remove-Item -LiteralPath $runRoot -Recurse -Force
}

$inputDir = Join-Path $runRoot "input"
$outputDir = Join-Path $runRoot "output"
$logsDir = Join-Path $runRoot "logs"

New-Item -ItemType Directory -Path $inputDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

$fixtures = @{
    "alpha.txt" = "alpha river cloud stone lantern maple comet"
    "beta.txt" = "beta forest signal harbor velvet magnet copper orbit"
    "gamma.txt" = "gamma engine mirror quartz anchor cedar tunnel ember"
}

foreach ($entry in $fixtures.GetEnumerator()) {
    $path = Join-Path $inputDir $entry.Key
    Write-Utf8NoBomFile -Path $path -Content $entry.Value
}

$multiTurnTemplate = @"
# Multi Turn Observations

- Run label: $RunLabel
- Status: pending
- Notes:
"@

$providerTemplate = @"
# Provider Observations

- Run label: $RunLabel
- Provider dashboard checked: no
- Requested model:
- Billed model:
- Token usage:
- Silent downgrade observed:
- Notes:
"@

Write-Utf8NoBomFile -Path (Join-Path $logsDir "multi_turn_observations.md") -Content $multiTurnTemplate
Write-Utf8NoBomFile -Path (Join-Path $logsDir "provider_observations.md") -Content $providerTemplate

$manifest = [ordered]@{
    run_label = $RunLabel
    created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    suite_root = $suiteRoot
    run_root = $runRoot
    expected_files = @(
        "input\alpha.txt",
        "input\beta.txt",
        "input\gamma.txt",
        "output\environment_snapshot.json",
        "output\summary.json",
        "output\report.md",
        "output\report.sha256.txt",
        "input\long_context.txt",
        "output\long_context_check.txt",
        "logs\repeated_commands.json",
        "output\tool_chain_result.json",
        "logs\validator_summary.json",
        "output\final_evaluation.md",
        "logs\multi_turn_observations.md",
        "logs\provider_observations.md"
    )
}

$manifestJson = $manifest | ConvertTo-Json -Depth 6
Write-Utf8NoBomFile -Path (Join-Path $runRoot "run_manifest.json") -Content $manifestJson

Write-Output "Prepared run directory: $runRoot"
