# hooks 完整验证脚本
# 在全新 PowerShell 终端中执行: cd H:\claude_worke; .\verify-hooks.ps1

$ErrorActionPreference = "Continue"
$hookWrite = "H:\claude_worke\.claude\hooks\gate-write.js"
$hookBash  = "H:\claude_worke\.claude\hooks\gate-bash.js"
$featureJson = "H:\claude_worke\features\example-login\feature.json"

function Set-FeatureStatus {
    param([string]$status)
    $content = [System.IO.File]::ReadAllText($featureJson)
    $content = $content -replace '"status":\s*"[^"]*"', ('"status": "' + $status + '"')
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($featureJson, $content, $utf8NoBom)
    Write-Host "  [feature.json status -> $status]" -ForegroundColor DarkGray
}

function Run-Hook {
    param(
        [string]$hook,
        [string]$json,
        [string]$testId,
        [string]$desc,
        [string]$expect
    )
    Write-Host ""
    Write-Host "  [$testId] $desc" -ForegroundColor Cyan
    Write-Host "  expect: $expect" -ForegroundColor DarkGray
    $result = $json | node $hook 2>&1
    $code = $LASTEXITCODE
    if ($result) {
        Write-Host "  output: $result" -ForegroundColor Yellow
    }
    if (($expect -match "BLOCK") -and ($code -eq 2)) {
        Write-Host "  exitcode: $code  =>  PASS" -ForegroundColor Green
    } elseif (($expect -match "ALLOW") -and ($code -eq 0)) {
        Write-Host "  exitcode: $code  =>  PASS" -ForegroundColor Green
    } else {
        Write-Host "  exitcode: $code  =>  FAIL !!!" -ForegroundColor Red
    }
    return $code
}

$pass = 0
$fail = 0
$total = 0

function Record {
    param([int]$code, [int]$expectCode)
    $script:total++
    if ($code -eq $expectCode) { $script:pass++ } else { $script:fail++ }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "  Hooks Verification (6 groups, 18 tests)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White

# === save original ===
$originalContent = [System.IO.File]::ReadAllText($featureJson)

# ============================================================
# 1: gate-write block (no active feature)
# ============================================================
Write-Host ""
Write-Host "--- 1: gate-write block (status=done, no active feature) ---" -ForegroundColor Magenta
Set-FeatureStatus "done"

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/src/test.js","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "1a" -desc "Write src/test.js (no active feature)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Edit","tool_input":{"file_path":"H:/claude_worke/src/app.js","old_string":"a","new_string":"b"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "1b" -desc "Edit src/app.js (no active feature)" -expect "BLOCK"
Record -code $c -expectCode 2

# ============================================================
# 2: gate-write exempt paths
# ============================================================
Write-Host ""
Write-Host "--- 2: gate-write exempt paths (should always allow) ---" -ForegroundColor Magenta

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/docs/test.md","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "2a" -desc "Write docs/test.md (exempt)" -expect "ALLOW"
Record -code $c -expectCode 0

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/.claude/config.json","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "2b" -desc "Write .claude/config.json (exempt)" -expect "ALLOW"
Record -code $c -expectCode 0

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/features/test/note.md","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "2c" -desc "Write features/test/note.md (exempt)" -expect "ALLOW"
Record -code $c -expectCode 0

# ============================================================
# 3: gate-bash dangerous commands (blacklist mode)
# ============================================================
Write-Host ""
Write-Host "--- 3: gate-bash dangerous commands (status=implementing, blacklist) ---" -ForegroundColor Magenta
Set-FeatureStatus "implementing"

$j = '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "3a" -desc "git push --force (dangerous)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "3b" -desc "rm -rf / (dangerous)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Bash","tool_input":{"command":"DROP TABLE users;"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "3c" -desc "DROP TABLE (dangerous)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "3d" -desc "git status (safe)" -expect "ALLOW"
Record -code $c -expectCode 0

# ============================================================
# 4: gate-write allowed_paths matching
# ============================================================
Write-Host ""
Write-Host "--- 4: allowed_paths matching (status=implementing) ---" -ForegroundColor Magenta

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/src/auth/login.js","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "4a" -desc "src/auth/login.js (in allowed_paths)" -expect "ALLOW"
Record -code $c -expectCode 0

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/src/core/engine.js","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "4b" -desc "src/core/engine.js (in forbidden_paths)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/src/other/util.js","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "4c" -desc "src/other/util.js (not in any list)" -expect "BLOCK"
Record -code $c -expectCode 2

# ============================================================
# 5: end-to-end verifying status (whitelist mode)
# ============================================================
Write-Host ""
Write-Host "--- 5: verifying status (whitelist mode) ---" -ForegroundColor Magenta
Set-FeatureStatus "verifying"

$j = '{"tool_name":"Bash","tool_input":{"command":"npm run lint"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "5a" -desc "npm run lint (in required_checks)" -expect "ALLOW"
Record -code $c -expectCode 0

$j = '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "5b" -desc "ls -la (not in required_checks)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Write","tool_input":{"file_path":"H:/claude_worke/src/auth/login.js","content":"x"}}'
$c = Run-Hook -hook $hookWrite -json $j -testId "5c" -desc "src/auth/login.js (verifying + allowed)" -expect "ALLOW"
Record -code $c -expectCode 0

# ============================================================
# 6: verifying 模式命令拼接绕过测试（修复验证）
# ============================================================
Write-Host ""
Write-Host "--- 6: verifying command injection bypass tests ---" -ForegroundColor Magenta

$j = '{"tool_name":"Bash","tool_input":{"command":"npm run lint && rm -rf /"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "6a" -desc "npm run lint && rm -rf / (combinator bypass)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Bash","tool_input":{"command":"npm run lint ; echo hacked"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "6b" -desc "npm run lint ; echo hacked (semicolon bypass)" -expect "BLOCK"
Record -code $c -expectCode 2

$j = '{"tool_name":"Bash","tool_input":{"command":"npm run lint | cat"}}'
$c = Run-Hook -hook $hookBash -json $j -testId "6c" -desc "npm run lint | cat (pipe bypass)" -expect "BLOCK"
Record -code $c -expectCode 2

# === restore original ===
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($featureJson, $originalContent, $utf8NoBom)

# ============================================================
# summary
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "  Results" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host ""
Write-Host "  Total: $total" -ForegroundColor White
Write-Host "  Pass:  $pass" -ForegroundColor Green
if ($fail -gt 0) {
    Write-Host "  Fail:  $fail" -ForegroundColor Red
} else {
    Write-Host "  Fail:  $fail" -ForegroundColor Green
}
Write-Host ""
if ($fail -eq 0) {
    Write-Host "  ALL PASSED - hooks verification complete" -ForegroundColor Green
} else {
    Write-Host "  FAILURES DETECTED - check details above" -ForegroundColor Red
}
Write-Host ""
Write-Host "  [feature.json restored to original state]" -ForegroundColor DarkGray
Write-Host ""
