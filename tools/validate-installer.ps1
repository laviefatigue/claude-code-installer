# ============================================================================
# INSTALLER VALIDATION SCRIPT
# Tests each component's detection, URLs, and winget IDs locally
# Run: powershell -ExecutionPolicy Bypass -File tools\validate-installer.ps1
# ============================================================================

param([switch]$Verbose)

$ErrorActionPreference = "SilentlyContinue"
$pass = 0
$fail = 0
$warn = 0

function Test-Check {
    param([string]$Name, [bool]$Result, [string]$Detail = "")
    if ($Result) {
        Write-Host "  PASS " -NoNewline -ForegroundColor Green
        Write-Host "$Name" -NoNewline
        if ($Detail) { Write-Host " - $Detail" -ForegroundColor DarkGray } else { Write-Host "" }
        $script:pass++
    } else {
        Write-Host "  FAIL " -NoNewline -ForegroundColor Red
        Write-Host "$Name" -NoNewline
        if ($Detail) { Write-Host " - $Detail" -ForegroundColor Yellow } else { Write-Host "" }
        $script:fail++
    }
}

function Test-Warn {
    param([string]$Name, [string]$Detail = "")
    Write-Host "  WARN " -NoNewline -ForegroundColor Yellow
    Write-Host "$Name" -NoNewline
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor DarkGray } else { Write-Host "" }
    $script:warn++
}

function Test-Url {
    param([string]$Name, [string]$Url)
    try {
        $resp = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10
        $status = $resp.StatusCode
        Test-Check "$Name URL reachable" ($status -eq 200) "$Url -> $status"
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code) {
            Test-Check "$Name URL reachable" $false "$Url -> HTTP $code"
        } else {
            Test-Check "$Name URL reachable" $false "$Url -> $($_.Exception.Message)"
        }
    }
}

function Test-WingetPkg {
    param([string]$PackageId)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Test-Warn "winget: $PackageId" "winget not available on this machine"
        return
    }
    $result = winget show $PackageId 2>&1
    $found = $result -notmatch "No package found"
    Test-Check "winget: $PackageId exists" $found $(if ($found) { "found in winget" } else { "NOT FOUND in winget" })
}

Write-Host ""
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host "  INSTALLER VALIDATION" -ForegroundColor Cyan
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host ""

# ── Architecture Detection ──
Write-Host "  --- Architecture Detection ---" -ForegroundColor White
$isARM = ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") -or ($env:PROCESSOR_IDENTIFIER -match "ARMv")
Test-Check "Arch detection runs" $true "Detected: $(if ($isARM) { 'ARM64' } else { 'x64' }) ($env:PROCESSOR_ARCHITECTURE)"
Write-Host ""

# ── 1. Git ──
Write-Host "  --- [1] Git ---" -ForegroundColor White
$gitExe = "$env:ProgramFiles\Git\cmd\git.exe"
$gitBash = "$env:ProgramFiles\Git\bin\bash.exe"
Test-Check "git in PATH" (Get-Command git -EA SilentlyContinue) (& git --version 2>$null)
Test-Check "git.exe at known path" (Test-Path $gitExe) $gitExe
Test-Check "bash.exe (Git Bash) exists" (Test-Path $gitBash) $gitBash
Test-WingetPkg "Git.Git"
Test-Url "Git releases API" "https://api.github.com/repos/git-for-windows/git/releases/latest"
Write-Host ""

# ── 2. Node.js ──
Write-Host "  --- [2] Node.js ---" -ForegroundColor White
$nodeExe = "$env:ProgramFiles\nodejs\node.exe"
$npmExe = "$env:ProgramFiles\nodejs\npm.cmd"
Test-Check "node in PATH" (Get-Command node -EA SilentlyContinue) (& node --version 2>$null)
Test-Check "node.exe at known path" (Test-Path $nodeExe) $nodeExe
Test-Check "npm.cmd at known path" (Test-Path $npmExe) $npmExe
Test-WingetPkg "OpenJS.NodeJS.LTS"
Write-Host ""

# ── 3. VS Code ──
Write-Host "  --- [3] VS Code ---" -ForegroundColor White
$codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
$codeFound = (Test-Path $codeExe) -or (Test-Path $codeExeAlt) -or (Get-Command code -EA SilentlyContinue)
Test-Check "VS Code found" $codeFound $(if (Test-Path $codeExe) { $codeExe } elseif (Test-Path $codeExeAlt) { $codeExeAlt } else { "via PATH" })
Test-WingetPkg "Microsoft.VisualStudioCode"
$vsArch = if ($isARM) { "win32-arm64" } else { "win32-x64" }
Test-Url "VS Code download" "https://code.visualstudio.com/sha/download?build=stable&os=$vsArch"
Write-Host ""

# ── 4. Claude Code ──
Write-Host "  --- [4] Claude Code ---" -ForegroundColor White
$claudeCmd = "$env:APPDATA\npm\claude.cmd"
$claudeLocal = "$env:USERPROFILE\.local\bin\claude.exe"
$claudeFound = (Test-Path $claudeCmd) -or (Test-Path $claudeLocal) -or (Get-Command claude -EA SilentlyContinue)
Test-Check "claude found" $claudeFound $(& claude --version 2>$null)
Test-Url "Claude official installer" "https://claude.ai/install.ps1"
Write-Host ""

# ── 5. Python ──
Write-Host "  --- [5] Python ---" -ForegroundColor White
$pyFound = Get-Command python -EA SilentlyContinue
Test-Check "python in PATH" $pyFound (& python --version 2>$null)

# Check all known Python paths
$pyPaths = @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:ProgramFiles\Python314\python.exe",
    "$env:ProgramFiles\Python313\python.exe",
    "$env:ProgramFiles\Python312\python.exe"
)
$pyFoundPath = $false
foreach ($p in $pyPaths) {
    if (Test-Path $p) {
        Test-Check "python.exe at known path" $true $p
        $pyFoundPath = $true
        break
    }
}
if (-not $pyFoundPath) { Test-Warn "No python.exe at known paths" "Checking: Python314, Python313, Python312" }

Test-WingetPkg "Python.Python.3.13"
$pyArch = if ($isARM) { "arm64" } else { "amd64" }
Test-Url "Python 3.13.5 installer" "https://www.python.org/ftp/python/3.13.5/python-3.13.5-$pyArch.exe"
Write-Host ""

# ── 6. uv ──
Write-Host "  --- [6] uv ---" -ForegroundColor White
$uvExe = "$env:USERPROFILE\.local\bin\uv.exe"
Test-Check "uv in PATH" (Get-Command uv -EA SilentlyContinue) (& uv --version 2>$null)
Test-Check "uv.exe at known path" (Test-Path $uvExe) $uvExe
Test-Url "uv installer script" "https://astral.sh/uv/install.ps1"
Write-Host ""

# ── 7. Playwright ──
Write-Host "  --- [7] Playwright ---" -ForegroundColor White
$pwVersion = & python -m playwright --version 2>$null
$pwInstalled = ($LASTEXITCODE -eq 0 -and $pwVersion)
Test-Check "playwright pip package" $pwInstalled $(if ($pwVersion) { $pwVersion } else { "not installed" })

$browserDir = "$env:LOCALAPPDATA\ms-playwright"
$chromiumDirs = Get-ChildItem "$browserDir\chromium-*" -Directory -EA SilentlyContinue
Test-Check "chromium browser binaries" ($chromiumDirs.Count -gt 0) $(if ($chromiumDirs) { $chromiumDirs[0].Name } else { "$browserDir\chromium-* not found" })

# Verify playwright can actually launch
if ($pwInstalled -and $chromiumDirs.Count -gt 0) {
    $testScript = @"
import sys
try:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto('about:blank')
        browser.close()
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
"@
    $testResult = echo $testScript | python 2>&1
    Test-Check "playwright chromium launches" ($testResult -match "OK") $testResult
}
Write-Host ""

# ── 8. GitHub CLI ──
Write-Host "  --- [8] GitHub CLI ---" -ForegroundColor White
$ghExe = "$env:ProgramFiles\GitHub CLI\gh.exe"
$ghFound = (Test-Path $ghExe) -or (Get-Command gh -EA SilentlyContinue)
Test-Check "gh found" $ghFound $(& gh --version 2>$null | Select-Object -First 1)
if (-not $ghFound) {
    Test-Warn "GitHub CLI not installed" "This is also missing on your machine - install: winget install GitHub.cli"
}
Test-WingetPkg "GitHub.cli"
Test-Url "GitHub CLI releases API" "https://api.github.com/repos/cli/cli/releases/latest"

# Check gh auth status if installed
if ($ghFound) {
    $authOk = & gh auth status 2>&1
    Test-Check "gh authenticated" ($LASTEXITCODE -eq 0) $(if ($LASTEXITCODE -eq 0) { "signed in" } else { "not signed in" })
}
Write-Host ""

# ── 9. Git Identity ──
Write-Host "  --- [9] Git Identity ---" -ForegroundColor White
$gitName = & git config --global user.name 2>$null
$gitEmail = & git config --global user.email 2>$null
Test-Check "git user.name set" ($null -ne $gitName -and $gitName -ne "") $gitName
Test-Check "git user.email set" ($null -ne $gitEmail -and $gitEmail -ne "") $gitEmail
Write-Host ""

# ── 10. ExecutionPolicy ──
Write-Host "  --- [10] ExecutionPolicy ---" -ForegroundColor White
$policy = Get-ExecutionPolicy -Scope CurrentUser
$policyOk = ($policy -ne "Restricted" -and $policy -ne "Undefined")
Test-Check "ExecutionPolicy not restricted" $policyOk "CurrentUser scope: $policy"
Write-Host ""

# ── 11. VS Code Extensions ──
Write-Host "  --- [11] VS Code Extensions ---" -ForegroundColor White
$codePath = if (Test-Path $codeExe) { $codeExe } elseif (Test-Path $codeExeAlt) { $codeExeAlt } else { $null }
if ($codePath) {
    $exts = & $codePath --list-extensions 2>$null
    if ($exts) {
        Test-Check "anthropic.claude-code extension" ($exts -match "anthropic.claude-code") ""
        Test-Check "foam.foam-vscode extension" ($exts -match "foam.foam-vscode") ""
    } else {
        Test-Warn "Could not list extensions" "code --list-extensions returned nothing"
    }
} else {
    Test-Warn "VS Code not at known path" "cannot check extensions"
}
Write-Host ""

# ── Install Script Syntax Check ──
Write-Host "  --- Script Syntax ---" -ForegroundColor White
$ps1Path = Join-Path $PSScriptRoot "..\install.ps1"
if (Test-Path $ps1Path) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ps1Path, [ref]$tokens, [ref]$errors) | Out-Null
    Test-Check "install.ps1 parses without errors" ($errors.Count -eq 0) "$($errors.Count) parse errors"
    if ($errors.Count -gt 0) {
        foreach ($e in $errors) {
            Write-Host "    -> Line $($e.Extent.StartLineNumber): $($e.Message)" -ForegroundColor Red
        }
    }
} else {
    Test-Warn "install.ps1 not found at $ps1Path"
}
Write-Host ""

# ── Summary ──
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host "  RESULTS: " -NoNewline
Write-Host "$pass PASS" -NoNewline -ForegroundColor Green
Write-Host " / " -NoNewline
Write-Host "$fail FAIL" -NoNewline -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })
Write-Host " / " -NoNewline
Write-Host "$warn WARN" -ForegroundColor Yellow
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host ""

exit $fail
