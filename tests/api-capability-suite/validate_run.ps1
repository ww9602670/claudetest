param(
    [Parameter(Mandatory = $true)]
    [string]$RunLabel
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
$runRoot = Join-Path (Join-Path $suiteRoot "runs") $RunLabel
$inputDir = Join-Path $runRoot "input"
$outputDir = Join-Path $runRoot "output"
$logsDir = Join-Path $runRoot "logs"
$summaryPath = Join-Path $outputDir "summary.json"
$reportPath = Join-Path $outputDir "report.md"
$hashPath = Join-Path $outputDir "report.sha256.txt"
$longContextPath = Join-Path $inputDir "long_context.txt"
$longContextCheckPath = Join-Path $outputDir "long_context_check.txt"
$environmentPath = Join-Path $outputDir "environment_snapshot.json"
$repeatedPath = Join-Path $logsDir "repeated_commands.json"
$toolChainPath = Join-Path $outputDir "tool_chain_result.json"
$finalEvaluationPath = Join-Path $outputDir "final_evaluation.md"
$summaryOutPath = Join-Path $logsDir "validator_summary.json"

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Name,
        [bool]$Success,
        [string]$Detail
    )

    $checks.Add([pscustomobject]@{
        name = $Name
        success = $Success
        detail = $Detail
    }) | Out-Null
}

function Read-JsonFile {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-ExpectedWordData {
    param([string[]]$Paths)

    $allWords = New-Object System.Collections.Generic.List[string]
    $wordCounts = [ordered]@{}

    foreach ($path in $Paths) {
        $name = Split-Path $path -Leaf
        $text = (Get-Content -LiteralPath $path -Raw).Trim()
        $words = @($text -split "\s+" | Where-Object { $_ })
        $wordCounts[$name] = $words.Count
        foreach ($word in $words) {
            $allWords.Add($word) | Out-Null
        }
    }

    $unique = @($allWords | Sort-Object -Unique)
    $longest = ($unique | Sort-Object Length, @{ Expression = { $_ }; Descending = $false } -Descending | Select-Object -First 1)

    return [pscustomobject]@{
        WordCounts = $wordCounts
        UniqueWords = $unique
        LongestWord = $longest
        TotalUniqueWordCount = $unique.Count
    }
}

if (-not (Test-Path $runRoot)) {
    throw "Run directory does not exist: $runRoot"
}

$requiredFiles = @(
    (Join-Path $inputDir "alpha.txt"),
    (Join-Path $inputDir "beta.txt"),
    (Join-Path $inputDir "gamma.txt"),
    $environmentPath,
    $summaryPath,
    $reportPath,
    $hashPath,
    $longContextPath,
    $longContextCheckPath,
    $repeatedPath,
    $toolChainPath,
    $finalEvaluationPath
)

foreach ($path in $requiredFiles) {
    Add-Check -Name ("exists:" + (Resolve-Path -LiteralPath (Split-Path $path -Parent) | ForEach-Object { Join-Path $_ (Split-Path $path -Leaf) })) -Success (Test-Path $path) -Detail ($(if (Test-Path $path) { "present" } else { "missing" }))
}

$inputFiles = @(
    (Join-Path $inputDir "alpha.txt"),
    (Join-Path $inputDir "beta.txt"),
    (Join-Path $inputDir "gamma.txt")
)

$expected = Get-ExpectedWordData -Paths $inputFiles

if (Test-Path $environmentPath) {
    try {
        $environment = Read-JsonFile -Path $environmentPath
        $hasRequiredEnvironmentFields = @(
            "run_label",
            "timestamp_utc",
            "cwd",
            "anthropic_base_url",
            "key_source",
            "api_key_masked",
            "model_hints",
            "self_reported_model",
            "notes"
        ) | ForEach-Object { $null -ne $environment.$_ }
        Add-Check -Name "environment_snapshot.schema" -Success (-not ($hasRequiredEnvironmentFields -contains $false)) -Detail "checked required fields"
        Add-Check -Name "environment_snapshot.run_label" -Success ($environment.run_label -eq $RunLabel) -Detail ("actual=" + $environment.run_label)
    }
    catch {
        Add-Check -Name "environment_snapshot.json" -Success $false -Detail $_.Exception.Message
    }
}

if (Test-Path $summaryPath) {
    try {
        $summary = Read-JsonFile -Path $summaryPath
        $actualFiles = @($summary.files)
        $actualUniqueWords = @($summary.combined_unique_words)
        $uniqueDiff = @(Compare-Object -ReferenceObject $expected.UniqueWords -DifferenceObject $actualUniqueWords)
        $wordCountsMatch = $true
        foreach ($pair in $expected.WordCounts.GetEnumerator()) {
            if ($summary.word_counts.($pair.Key) -ne $pair.Value) {
                $wordCountsMatch = $false
                break
            }
        }

        Add-Check -Name "summary.files" -Success (($actualFiles -join ",") -eq "alpha.txt,beta.txt,gamma.txt") -Detail ($actualFiles -join ",")
        Add-Check -Name "summary.word_counts" -Success $wordCountsMatch -Detail "compared against input files"
        Add-Check -Name "summary.unique_words" -Success ($uniqueDiff.Count -eq 0) -Detail ("count=" + $actualUniqueWords.Count)
        Add-Check -Name "summary.longest_word" -Success ($summary.longest_word -eq $expected.LongestWord) -Detail ("actual=" + $summary.longest_word)
        Add-Check -Name "summary.total_unique_word_count" -Success ($summary.total_unique_word_count -eq $expected.TotalUniqueWordCount) -Detail ("actual=" + $summary.total_unique_word_count)
        Add-Check -Name "summary.generated_by_model" -Success (-not [string]::IsNullOrWhiteSpace([string]$summary.generated_by_model)) -Detail "non-empty check"
    }
    catch {
        Add-Check -Name "summary.json" -Success $false -Detail $_.Exception.Message
    }
}

if (Test-Path $reportPath) {
    $report = Get-Content -LiteralPath $reportPath -Raw
    Add-Check -Name "report.title" -Success ($report -match "(?m)^#\s+") -Detail "title present"
    Add-Check -Name "report.includes_alpha" -Success ($report -match "alpha\.txt") -Detail "alpha.txt"
    Add-Check -Name "report.includes_beta" -Success ($report -match "beta\.txt") -Detail "beta.txt"
    Add-Check -Name "report.includes_gamma" -Success ($report -match "gamma\.txt") -Detail "gamma.txt"
    Add-Check -Name "report.includes_unique_count" -Success ($report -match [regex]::Escape([string]$expected.TotalUniqueWordCount)) -Detail ([string]$expected.TotalUniqueWordCount)
    Add-Check -Name "report.includes_longest_word" -Success ($report -match [regex]::Escape($expected.LongestWord)) -Detail $expected.LongestWord
    Add-Check -Name "report.includes_run_label" -Success ($report -match [regex]::Escape($RunLabel)) -Detail $RunLabel
}

if ((Test-Path $reportPath) -and (Test-Path $hashPath)) {
    $expectedHash = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashText = (Get-Content -LiteralPath $hashPath -Raw).Trim()
    Add-Check -Name "report.hash_format" -Success ($hashText -match "^sha256:\s[a-f0-9]{64}$") -Detail $hashText
    Add-Check -Name "report.hash_match" -Success ($hashText -eq ("sha256: " + $expectedHash)) -Detail $expectedHash
}

if ((Test-Path $longContextPath) -and (Test-Path $longContextCheckPath)) {
    $longText = Get-Content -LiteralPath $longContextPath -Raw
    $longTextPreview = $longText.TrimEnd("`r", "`n")
    $checkText = Get-Content -LiteralPath $longContextCheckPath -Raw
    $parsedLongContext = @{}
    foreach ($line in ($checkText -split "\r?\n")) {
        if ($line -match "^(character_count|first_40|last_40):\s?(.*)$") {
            $parsedLongContext[$matches[1]] = $matches[2]
        }
    }

    $characterCountOk = $parsedLongContext.ContainsKey("character_count") -and ([int]$parsedLongContext["character_count"] -eq $longText.Length)
    $first40Ok = $parsedLongContext.ContainsKey("first_40") -and ($parsedLongContext["first_40"] -eq $longTextPreview.Substring(0, [Math]::Min(40, $longTextPreview.Length)))
    $last40Ok = $parsedLongContext.ContainsKey("last_40") -and ($parsedLongContext["last_40"] -eq $longTextPreview.Substring([Math]::Max(0, $longTextPreview.Length - 40)))

    Add-Check -Name "long_context.length" -Success ($longText.Length -ge 5000) -Detail ("actual=" + $longText.Length)
    Add-Check -Name "long_context.check.character_count" -Success $characterCountOk -Detail "character_count compared"
    Add-Check -Name "long_context.check.first_40" -Success $first40Ok -Detail "first_40 compared"
    Add-Check -Name "long_context.check.last_40" -Success $last40Ok -Detail "last_40 compared"
}

if (Test-Path $repeatedPath) {
    try {
        $repeated = Read-JsonFile -Path $repeatedPath
        $runs = @($repeated.runs)
        $countOk = $runs.Count -eq 10
        $ids = @($runs | ForEach-Object { [int]$_.id } | Sort-Object)
        $idOk = (($ids -join ",") -eq "1,2,3,4,5,6,7,8,9,10")
        $badRuns = @($runs | Where-Object {
            ($null -eq $_.id) -or
            ([string]::IsNullOrWhiteSpace([string]$_.command)) -or
            ($null -eq $_.success)
        })
        $schemaOk = $badRuns.Count -eq 0
        $successCount = ($runs | Where-Object { $_.success -eq $true }).Count

        Add-Check -Name "repeated_commands.count" -Success $countOk -Detail ("actual=" + $runs.Count)
        Add-Check -Name "repeated_commands.ids" -Success $idOk -Detail ($ids -join ",")
        Add-Check -Name "repeated_commands.schema" -Success $schemaOk -Detail "required fields checked"
        Add-Check -Name "repeated_commands.success_rate" -Success ($successCount -ge 8) -Detail ("successes=" + $successCount)
    }
    catch {
        Add-Check -Name "repeated_commands.json" -Success $false -Detail $_.Exception.Message
    }
}

if (Test-Path $toolChainPath) {
    try {
        $toolChain = Read-JsonFile -Path $toolChainPath
        $sources = @($toolChain.source_files_read)
        Add-Check -Name "tool_chain.sources" -Success (($sources -contains "report.sha256.txt") -and ($sources -contains "repeated_commands.json")) -Detail ($sources -join ",")
        Add-Check -Name "tool_chain.report_sha256" -Success (-not [string]::IsNullOrWhiteSpace([string]$toolChain.report_sha256)) -Detail ([string]$toolChain.report_sha256)
        Add-Check -Name "tool_chain.success_count" -Success ($toolChain.repeated_command_success_count -ge 0) -Detail ([string]$toolChain.repeated_command_success_count)
        Add-Check -Name "tool_chain.generated_by_model" -Success (-not [string]::IsNullOrWhiteSpace([string]$toolChain.generated_by_model)) -Detail "non-empty check"
    }
    catch {
        Add-Check -Name "tool_chain_result.json" -Success $false -Detail $_.Exception.Message
    }
}

if (Test-Path $finalEvaluationPath) {
    $finalEvaluation = Get-Content -LiteralPath $finalEvaluationPath -Raw
    $sections = @(
        "Overall Result",
        "Succeeded Steps",
        "Failed Steps",
        "Observed Stability Risks",
        "Manual Verification Needed",
        "Recommendation"
    )
    foreach ($section in $sections) {
        Add-Check -Name ("final_evaluation.section." + $section) -Success ($finalEvaluation -match [regex]::Escape("# " + $section)) -Detail $section
    }

    $recommendationMatch = [regex]::Match($finalEvaluation, "(?ms)^#\s+Recommendation\s+(.+?)\s*$")
    $recommendationValue = ""
    if ($recommendationMatch.Success) {
        $recommendationValue = $recommendationMatch.Groups[1].Value.Trim().Split([Environment]::NewLine)[0].Trim()
    }
    Add-Check -Name "final_evaluation.recommendation_value" -Success (@("usable", "usable_with_caution", "not_stable_enough") -contains $recommendationValue) -Detail ("actual=" + $recommendationValue)
}

$failedChecks = @($checks | Where-Object { -not $_.success })
$criticalFailureNames = @(
    ("exists:" + (Join-Path $outputDir "environment_snapshot.json")),
    ("exists:" + (Join-Path $outputDir "summary.json")),
    ("exists:" + (Join-Path $outputDir "report.md")),
    ("exists:" + (Join-Path $outputDir "report.sha256.txt")),
    ("exists:" + (Join-Path $inputDir "long_context.txt")),
    ("exists:" + (Join-Path $outputDir "long_context_check.txt")),
    ("exists:" + (Join-Path $logsDir "repeated_commands.json")),
    ("exists:" + (Join-Path $outputDir "tool_chain_result.json")),
    ("exists:" + (Join-Path $outputDir "final_evaluation.md")),
    "summary.files",
    "summary.word_counts",
    "summary.unique_words",
    "report.hash_match",
    "long_context.length",
    "long_context.check.character_count",
    "repeated_commands.count",
    "repeated_commands.schema",
    "tool_chain.sources"
)
$criticalFailures = @($failedChecks | Where-Object { $criticalFailureNames -contains $_.name })

$autoRecommendation = if ($criticalFailures.Count -gt 0) {
    "not_stable_enough"
}
elseif ($failedChecks.Count -gt 0) {
    "usable_with_caution"
}
else {
    "usable"
}

$summaryOut = [ordered]@{
    run_label = $RunLabel
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    total_checks = $checks.Count
    passed_checks = ($checks | Where-Object { $_.success }).Count
    failed_checks = $failedChecks.Count
    auto_recommendation = $autoRecommendation
    critical_failures = @($criticalFailures | Select-Object -ExpandProperty name)
    checks = $checks
}

$summaryJson = $summaryOut | ConvertTo-Json -Depth 6
Write-Utf8NoBomFile -Path $summaryOutPath -Content $summaryJson
Write-Output ("Validator summary written to: " + $summaryOutPath)
