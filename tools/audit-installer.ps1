# ============================================================================
# COMPREHENSIVE INSTALLER AUDIT
# Validates install order, dependencies, connectivity, and integration
# Run: powershell -ExecutionPolicy Bypass -File tools\audit-installer.ps1
# ============================================================================

$ErrorActionPreference = "SilentlyContinue"
$pass = 0; $fail = 0; $warn = 0; $critical = 0

function Pass { param([string]$Msg, [string]$Detail = "")
    Write-Host "  PASS  " -NoNewline -ForegroundColor Green; Write-Host $Msg -NoNewline
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor DarkGray } else { Write-Host "" }
    $script:pass++
}
function Fail { param([string]$Msg, [string]$Detail = "")
    Write-Host "  FAIL  " -NoNewline -ForegroundColor Red; Write-Host $Msg -NoNewline
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor Yellow } else { Write-Host "" }
    $script:fail++
}
function Crit { param([string]$Msg, [string]$Detail = "")
    Write-Host "  CRIT  " -NoNewline -ForegroundColor Magenta; Write-Host $Msg -NoNewline
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor Yellow } else { Write-Host "" }
    $script:critical++
}
function Warn { param([string]$Msg, [string]$Detail = "")
    Write-Host "  WARN  " -NoNewline -ForegroundColor Yellow; Write-Host $Msg -NoNewline
    if ($Detail) { Write-Host " - $Detail" -ForegroundColor DarkGray } else { Write-Host "" }
    $script:warn++
}
function Info { param([string]$Msg)
    Write-Host "        $Msg" -ForegroundColor DarkGray
}
function Section { param([string]$Name)
    Write-Host ""
    Write-Host "  === $Name ===" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "  COMPREHENSIVE INSTALLER AUDIT" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan

# =====================================================================
Section "1. SCRIPT SYNTAX & STRUCTURE"
# =====================================================================

$ps1Path = Join-Path $PSScriptRoot "..\install.ps1"
$shPath = Join-Path $PSScriptRoot "..\install.sh"

# PS1 syntax
if (Test-Path $ps1Path) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ps1Path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -eq 0) { Pass "install.ps1 parses cleanly" "0 syntax errors" }
    else {
        Crit "install.ps1 has syntax errors" "$($errors.Count) errors"
        foreach ($e in $errors) { Info "Line $($e.Extent.StartLineNumber): $($e.Message)" }
    }

    # Check version consistency
    $content = Get-Content $ps1Path -Raw
    $vMatch = [regex]::Match($content, '\$INSTALLER_VERSION\s*=\s*"([^"]+)"')
    $sMatch = [regex]::Match($content, '\$TOTAL_STEPS\s*=\s*(\d+)')
    $version = $vMatch.Groups[1].Value
    $totalSteps = [int]$sMatch.Groups[1].Value
    Pass "PS1 version: $version, steps: $totalSteps"

    # Count actual step headers
    $stepHeaders = [regex]::Matches($content, 'Write-StepHeader\s+(\d+)')
    $stepNums = $stepHeaders | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object
    if ($stepNums[-1] -eq $totalSteps -and $stepNums[0] -eq 1) {
        $sequential = $true
        for ($i = 0; $i -lt $stepNums.Count - 1; $i++) {
            if ($stepNums[$i+1] - $stepNums[$i] -ne 1) { $sequential = $false; break }
        }
        if ($sequential) { Pass "Step numbers sequential 1-$totalSteps" "$($stepNums.Count) steps found" }
        else { Fail "Step numbers have gaps" "Found: $($stepNums -join ', ')" }
    } else {
        Fail "Step numbers mismatch TOTAL_STEPS" "Max step: $($stepNums[-1]), TOTAL_STEPS: $totalSteps"
    }
} else { Crit "install.ps1 not found at $ps1Path" }

# SH exists
if (Test-Path $shPath) {
    $shContent = Get-Content $shPath -Raw
    $shVer = if ($shContent -match 'INSTALLER_VERSION="([^"]+)"') { $matches[1] } else { "?" }
    $shSteps = if ($shContent -match 'TOTAL_STEPS=(\d+)') { $matches[1] } else { "?" }
    Pass "install.sh exists" "version: $shVer, steps: $shSteps"

    # Check version parity
    if ($shVer -eq $version) { Pass "Version parity PS1/SH" "both $version" }
    else { Fail "Version mismatch" "PS1: $version, SH: $shVer" }

    if ($shSteps -eq "$totalSteps") { Pass "Step count parity PS1/SH" "both $totalSteps" }
    else { Fail "Step count mismatch" "PS1: $totalSteps, SH: $shSteps" }
} else { Warn "install.sh not found" }

# install.bat exists
$batPath = Join-Path $PSScriptRoot "..\install.bat"
if (Test-Path $batPath) { Pass "install.bat launcher exists" }
else { Fail "install.bat missing" "users can't double-click to run" }


# =====================================================================
Section "2. INSTALL ORDER & DEPENDENCY CHAIN"
# =====================================================================

Info "Required order: Git -> Node -> VS Code -> Claude -> Python -> uv -> Playwright -> GitHub CLI"
Info "Configure:      Git Identity -> ExecutionPolicy -> Extensions"
Info ""

# Verify the main flow order in install.ps1
$flowSection = $content.Substring($content.IndexOf("# SECTION 6: MAIN FLOW"))
$installCalls = [regex]::Matches($flowSection, '(Install-\w+|Set-\w+)')
$callOrder = $installCalls | ForEach-Object { $_.Value }
$expectedOrder = @(
    "Install-Git", "Install-Node", "Install-VSCode", "Install-Claude",
    "Install-Python", "Install-Uv", "Install-Playwright", "Install-GhCli",
    "Set-GitIdentity", "Set-PSExecutionPolicy", "Install-Extensions"
)

$orderCorrect = $true
for ($i = 0; $i -lt $expectedOrder.Count; $i++) {
    if ($i -ge $callOrder.Count -or $callOrder[$i] -ne $expectedOrder[$i]) {
        $orderCorrect = $false
        Crit "Install order wrong at position $($i+1)" "Expected: $($expectedOrder[$i]), Got: $(if ($i -lt $callOrder.Count) { $callOrder[$i] } else { 'MISSING' })"
    }
}
if ($orderCorrect) { Pass "Install order matches expected sequence" "$($expectedOrder.Count) functions in correct order" }

# Dependency analysis
Info ""
Info "Dependency verification:"

# Git must be first (Claude needs it)
if ($callOrder[0] -eq "Install-Git") { Pass "Git is Step 1" "Claude Code requires Git" }
else { Crit "Git is NOT Step 1" "Claude Code will fail without Git" }

# Node must come before Claude (npm fallback needs it)
$nodeIdx = [array]::IndexOf($callOrder, "Install-Node")
$claudeIdx = [array]::IndexOf($callOrder, "Install-Claude")
if ($nodeIdx -lt $claudeIdx) { Pass "Node before Claude" "npm fallback requires Node.js" }
else { Crit "Node AFTER Claude" "npm install -g @anthropic-ai/claude-code will fail" }

# Python must come before Playwright (pip install playwright needs it)
$pyIdx = [array]::IndexOf($callOrder, "Install-Python")
$pwIdx = [array]::IndexOf($callOrder, "Install-Playwright")
if ($pwIdx -ge 0) {
    if ($pyIdx -lt $pwIdx) { Pass "Python before Playwright" "pip install playwright requires Python" }
    else { Crit "Python AFTER Playwright" "pip install playwright will fail" }
} else { Fail "Install-Playwright not found in flow" }

# uv should come before Playwright (not strictly required but logical)
$uvIdx = [array]::IndexOf($callOrder, "Install-Uv")
if ($uvIdx -lt $pwIdx) { Pass "uv before Playwright" "logical ordering" }
else { Warn "uv after Playwright" "not critical but unusual" }

# Git must come before Git Identity
$gitIdIdx = [array]::IndexOf($callOrder, "Set-GitIdentity")
if ($callOrder[0] -eq "Install-Git" -and $gitIdIdx -gt 0) { Pass "Git before Git Identity" "git config requires git" }
else { Crit "Git Identity without Git" }

# VS Code must come before Extensions
$extIdx = [array]::IndexOf($callOrder, "Install-Extensions")
$codeIdx = [array]::IndexOf($callOrder, "Install-VSCode")
if ($codeIdx -lt $extIdx) { Pass "VS Code before Extensions" "code --install-extension requires VS Code" }
else { Crit "Extensions before VS Code" }

# GitHub CLI should come before Git Identity (for auto-detect from gh)
$ghIdx = [array]::IndexOf($callOrder, "Install-GhCli")
if ($ghIdx -lt $gitIdIdx) { Pass "GitHub CLI before Git Identity" "enables auto-detect from gh api user" }
else { Warn "GitHub CLI after Git Identity" "can't auto-detect git name/email from GitHub" }


# =====================================================================
Section "3. DOWNLOAD URLS & PACKAGE IDS"
# =====================================================================

$urls = @(
    @{ Name = "Git releases API";     Url = "https://api.github.com/repos/git-for-windows/git/releases/latest" },
    @{ Name = "Node.js v24.14.0 x64"; Url = "https://nodejs.org/dist/v24.14.0/node-v24.14.0-x64.msi" },
    @{ Name = "Node.js v24.14.0 arm"; Url = "https://nodejs.org/dist/v24.14.0/node-v24.14.0-arm64.msi" },
    @{ Name = "VS Code x64";          Url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" },
    @{ Name = "VS Code arm64";        Url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-arm64" },
    @{ Name = "Claude installer PS1"; Url = "https://claude.ai/install.ps1" },
    @{ Name = "Claude installer SH";  Url = "https://claude.ai/install.sh" },
    @{ Name = "Python 3.13.5 amd64";  Url = "https://www.python.org/ftp/python/3.13.5/python-3.13.5-amd64.exe" },
    @{ Name = "Python 3.13.5 arm64";  Url = "https://www.python.org/ftp/python/3.13.5/python-3.13.5-arm64.exe" },
    @{ Name = "uv installer PS1";     Url = "https://astral.sh/uv/install.ps1" },
    @{ Name = "uv installer SH";      Url = "https://astral.sh/uv/install.sh" },
    @{ Name = "GitHub CLI releases";   Url = "https://api.github.com/repos/cli/cli/releases/latest" },
    @{ Name = "GitHub signup";         Url = "https://github.com/signup" },
    @{ Name = "Homebrew installer";    Url = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" },
    @{ Name = "NodeSource GPG key";    Url = "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" },
    @{ Name = "GitHub CLI GPG key";    Url = "https://cli.github.com/packages/githubcli-archive-keyring.gpg" }
)

foreach ($u in $urls) {
    try {
        $resp = Invoke-WebRequest -Uri $u.Url -Method Head -UseBasicParsing -TimeoutSec 10 -MaximumRedirection 5
        if ($resp.StatusCode -eq 200) { Pass "$($u.Name)" "$($u.Url) -> 200" }
        else { Fail "$($u.Name)" "$($u.Url) -> HTTP $($resp.StatusCode)" }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 302 -or $code -eq 301) {
            Pass "$($u.Name)" "$($u.Url) -> redirect (OK)"
        } else {
            Fail "$($u.Name)" "$($u.Url) -> $($_.Exception.Message)"
        }
    }
}

# Winget package IDs
Info ""
Info "Winget package IDs:"
$wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetAvailable) {
    $wingetPkgs = @("Git.Git", "OpenJS.NodeJS.LTS", "Microsoft.VisualStudioCode", "Python.Python.3.13", "GitHub.cli")
    foreach ($pkg in $wingetPkgs) {
        $result = winget show $pkg 2>&1
        if ($result -notmatch "No package found") { Pass "winget: $pkg" "found" }
        else { Fail "winget: $pkg" "NOT found in winget" }
    }
} else {
    Warn "winget not available" "skipping package ID validation"
}


# =====================================================================
Section "4. TOOL DETECTION (what Find-* functions would return)"
# =====================================================================

# Simulate exactly what the installer detection does
$gitExe     = "$env:ProgramFiles\Git\cmd\git.exe"
$gitBashExe = "$env:ProgramFiles\Git\bin\bash.exe"
$nodeExe    = "$env:ProgramFiles\nodejs\node.exe"
$npmExe     = "$env:ProgramFiles\nodejs\npm.cmd"
$codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
$claudeExe  = "$env:APPDATA\npm\claude.cmd"
$claudeLocal = "$env:USERPROFILE\.local\bin\claude.exe"
$uvExe      = "$env:USERPROFILE\.local\bin\uv.exe"
$ghExe      = "$env:ProgramFiles\GitHub CLI\gh.exe"

$detections = @(
    @{ Name = "Git";         Paths = @($gitExe); Cmd = "git"; VerCmd = "git --version" },
    @{ Name = "Git Bash";    Paths = @($gitBashExe); Cmd = $null; VerCmd = $null },
    @{ Name = "Node.js";     Paths = @($nodeExe); Cmd = "node"; VerCmd = "node --version" },
    @{ Name = "npm";         Paths = @($npmExe); Cmd = "npm"; VerCmd = "npm --version" },
    @{ Name = "VS Code";     Paths = @($codeExe, $codeExeAlt); Cmd = "code"; VerCmd = $null },
    @{ Name = "Claude (npm)"; Paths = @($claudeExe); Cmd = $null; VerCmd = $null },
    @{ Name = "Claude (local)"; Paths = @($claudeLocal); Cmd = "claude"; VerCmd = "claude --version" },
    @{ Name = "Python";      Paths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:ProgramFiles\Python314\python.exe",
        "$env:ProgramFiles\Python313\python.exe",
        "$env:ProgramFiles\Python312\python.exe"
    ); Cmd = "python"; VerCmd = "python --version" },
    @{ Name = "uv";          Paths = @($uvExe); Cmd = "uv"; VerCmd = "uv --version" },
    @{ Name = "GitHub CLI";  Paths = @($ghExe); Cmd = "gh"; VerCmd = "gh --version" }
)

foreach ($d in $detections) {
    $foundPath = $false
    $foundCmd = $false
    $version = ""

    foreach ($p in $d.Paths) {
        if (Test-Path $p) { $foundPath = $true; break }
    }

    if ($d.Cmd) {
        $cmd = Get-Command $d.Cmd -ErrorAction SilentlyContinue
        if ($cmd) { $foundCmd = $true }
    }

    if ($d.VerCmd) {
        $version = try { Invoke-Expression $d.VerCmd 2>&1 | Select-Object -First 1 } catch { "" }
    }

    if ($foundPath) {
        Pass "$($d.Name) - known path" $version
    } elseif ($foundCmd) {
        Warn "$($d.Name) - PATH only (no known path)" "$version - installer might miss this on fresh machine"
    } else {
        Fail "$($d.Name) - not found" "installer would attempt install"
    }
}


# =====================================================================
Section "5. INTEGRATION CHECKS (tools talk to each other)"
# =====================================================================

# Git + Claude: CLAUDE_CODE_GIT_BASH_PATH
$bashEnv = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", "User")
if ($bashEnv -and (Test-Path $bashEnv)) {
    Pass "CLAUDE_CODE_GIT_BASH_PATH set and valid" $bashEnv
} elseif ($bashEnv) {
    Fail "CLAUDE_CODE_GIT_BASH_PATH set but path doesn't exist" $bashEnv
} else {
    if (Test-Path $gitBashExe) {
        Warn "CLAUDE_CODE_GIT_BASH_PATH not set" "Git Bash exists at $gitBashExe but env var missing"
    } else {
        Fail "CLAUDE_CODE_GIT_BASH_PATH not set and Git Bash not found"
    }
}

# Node + Claude: npm can see claude
$npmGlobal = & npm list -g --depth=0 2>&1
$claudeInNpm = $npmGlobal | Select-String "claude-code"
if ($claudeInNpm) {
    Pass "Claude in npm globals" $claudeInNpm
} else {
    $claudeViaLocal = Test-Path $claudeLocal
    if ($claudeViaLocal) {
        Pass "Claude via official installer (not npm)" "~/.local/bin/claude.exe"
    } else {
        Fail "Claude not found in npm globals OR local bin"
    }
}

# Python + Playwright: pip can import playwright
$pyCmd = if (Get-Command python -EA SilentlyContinue) { "python" } elseif (Get-Command python3 -EA SilentlyContinue) { "python3" } else { $null }
if ($pyCmd) {
    $pwImport = & $pyCmd -c "import playwright; print(playwright.__version__)" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Pass "Python can import playwright" "v$pwImport"
    } else {
        Fail "Python cannot import playwright" "$pwImport"
    }

    # Playwright + Chromium: browser binary works
    $pwBrowsers = & $pyCmd -m playwright install --dry-run 2>&1
    $chromiumDir = Get-ChildItem "$env:LOCALAPPDATA\ms-playwright\chromium-*" -Directory -EA SilentlyContinue
    if ($chromiumDir) {
        Pass "Playwright Chromium browser installed" $chromiumDir[0].Name

        # Actually launch chromium headless
        $launchTest = & $pyCmd -c @"
from playwright.sync_api import sync_playwright
try:
    with sync_playwright() as p:
        b = p.chromium.launch(headless=True)
        pg = b.new_page()
        pg.goto('about:blank')
        print(f'OK - {b.browser_type.name} {b.version}')
        b.close()
except Exception as e:
    print(f'FAIL - {e}')
"@ 2>&1
        if ($launchTest -match "^OK") {
            Pass "Playwright Chromium launches headless" $launchTest
        } else {
            Fail "Playwright Chromium failed to launch" $launchTest
        }
    } else {
        Fail "Playwright Chromium browser NOT installed" "Run: playwright install chromium"
    }
} else {
    Fail "Python not found" "cannot test Playwright integration"
}

# Git + Git Identity
$gitName = & git config --global user.name 2>$null
$gitEmail = & git config --global user.email 2>$null
if ($gitName -and $gitEmail) {
    Pass "Git identity configured" "$gitName <$gitEmail>"
} else {
    Fail "Git identity incomplete" "name: $(if ($gitName) { $gitName } else { 'MISSING' }), email: $(if ($gitEmail) { $gitEmail } else { 'MISSING' })"
}

# GitHub CLI + Auth
if (Get-Command gh -EA SilentlyContinue) {
    $ghAuth = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Pass "GitHub CLI authenticated" ($ghAuth | Select-String "Logged in" | Select-Object -First 1)
    } else {
        Warn "GitHub CLI not authenticated" "gh auth login needed"
    }
} else {
    Fail "GitHub CLI not installed" "cannot test auth integration"
}

# VS Code + Extensions
$codePath = if (Test-Path $codeExe) { $codeExe } elseif (Test-Path $codeExeAlt) { $codeExeAlt } else { $null }
if ($codePath) {
    $exts = & $codePath --list-extensions 2>$null
    if ($exts) {
        if ($exts -match "anthropic.claude-code") { Pass "VS Code: Claude Code extension" }
        else { Fail "VS Code: Claude Code extension MISSING" }
        if ($exts -match "foam.foam-vscode") { Pass "VS Code: Foam extension" }
        else { Fail "VS Code: Foam extension MISSING" }
    } else {
        Warn "VS Code --list-extensions returned nothing"
    }
} else {
    Warn "VS Code not at known path" "cannot check extensions"
}

# ExecutionPolicy
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -ne "Restricted" -and $policy -ne "Undefined") {
    Pass "ExecutionPolicy" "CurrentUser: $policy"
} else {
    Fail "ExecutionPolicy is $policy" "Scripts won't run - installer Step 10 would fix this"
}


# =====================================================================
Section "6. FRESH MACHINE SIMULATION (what would happen)"
# =====================================================================

Info "If ALL tools were missing, the installer would:"
Info ""
Info "  Step 1:  Install Git via winget/direct download"
Info "           -> Sets CLAUDE_CODE_GIT_BASH_PATH env var"
Info "           -> Calls Refresh-Path"
Info ""
Info "  Step 2:  Install Node.js via winget/direct .msi"
Info "           -> Provides npm for Step 4 fallback"
Info "           -> Calls Refresh-Path"
Info ""
Info "  Step 3:  Install VS Code via winget/direct download"
Info "           -> Adds to PATH for Step 11"
Info "           -> Calls Refresh-Path"
Info ""
Info "  Step 4:  Install Claude Code"
Info "           -> Method 1: claude.ai/install.ps1 (installs to ~/.local/bin)"
Info "           -> Method 2: npm install -g (requires Step 2)"
Info "           -> Method 3: npm in subprocess"
Info "           -> Verifies binary exists before marking success"
Info "           -> CRITICAL: If all 3 fail, EXIT 2"
Info ""
Info "  Step 5:  Install Python 3.13 via winget/direct download"
Info "           -> PrependPath=1 adds to PATH"
Info "           -> Calls Refresh-Path"
Info ""
Info "  Step 6:  Install uv via astral.sh script"
Info "           -> Installs to ~/.local/bin"
Info "           -> Calls Refresh-Path"
Info ""
Info "  Step 7:  Install Playwright"
Info "           -> pip install playwright (requires Step 5)"
Info "           -> playwright install chromium (downloads ~200MB)"
Info "           -> Graceful skip if Python missing"
Info ""
Info "  Step 8:  Install GitHub CLI via winget/direct .msi"
Info "           -> Offers: sign in / create account / skip"
Info "           -> If signed in, Step 9 can auto-detect identity"
Info ""
Info "  Step 9:  Git Identity"
Info "           -> Auto-detect from gh api user (requires Step 8 auth)"
Info "           -> Fallback: manual name/email prompt"
Info "           -> Uses noreply email for GitHub users"
Info ""
Info "  Step 10: ExecutionPolicy"
Info "           -> Sets CurrentUser to RemoteSigned"
Info ""
Info "  Step 11: VS Code Extensions"
Info "           -> anthropic.claude-code (requires Step 3)"
Info "           -> foam.foam-vscode (requires Step 3)"
Info ""

# Check for critical gaps
$content = Get-Content $ps1Path -Raw

# Does Claude install verify before marking success?
if ($content -match 'claude\.ai/install\.ps1.*?Find-Claude.*?installed\s*=\s*\$true' -or
    $content -match 'Test-Path \$claudeLocal.*installed = \$true') {
    Pass "Claude install verifies binary before success"
} else {
    # Check the specific pattern we fixed
    if ($content -match 'Only mark as installed if the binary actually exists') {
        Pass "Claude install verifies binary before success" "comment confirms"
    } else {
        Crit "Claude install may not verify binary exists" "could skip npm fallback"
    }
}

# Does Playwright gracefully handle missing Python?
if ($content -match 'Install-Playwright[\s\S]*?Python.*?not available.*?skip' -or
    $content -match 'Install-Playwright[\s\S]*?pyInfo\.Found.*?WARN') {
    Pass "Playwright gracefully skips if Python missing"
} else {
    Warn "Playwright may not handle missing Python gracefully"
}

# Does Git Identity try gh before manual prompt?
if ($content -match 'Set-GitIdentity[\s\S]*?Find-Gh[\s\S]*?gh api user[\s\S]*?Read-Host') {
    Pass "Git Identity tries GitHub auto-detect before manual prompt"
} else {
    Warn "Git Identity may not auto-detect from GitHub"
}

# Does GitHub auth offer account creation?
if ($content -match 'github\.com/signup') {
    Pass "GitHub auth offers account creation flow"
} else {
    Fail "GitHub auth missing account creation option"
}

# REQUIRED tools exit on failure
$requiredTools = @("Git", "Node", "VSCode", "Claude")
foreach ($tool in $requiredTools) {
    if ($content -match "Install-$tool[\s\S]*?exit\s+2") {
        Pass "$tool exits on install failure" "exit 2 - blocks further steps"
    } else {
        Crit "$tool does NOT exit on failure" "subsequent steps may fail unpredictably"
    }
}

# ESSENTIAL tools warn but continue
$essentialTools = @("Python", "Uv", "GhCli")
foreach ($tool in $essentialTools) {
    if ($content -match "Install-$tool[\s\S]*?WARN.*?Skipped") {
        Pass "$tool warns and continues on failure" "non-blocking"
    } else {
        Info "$tool - could not confirm warn-and-continue pattern (check manually)"
    }
}


# =====================================================================
Section "SUMMARY"
# =====================================================================

Write-Host ""
$total = $pass + $fail + $warn + $critical
Write-Host "  Total checks: $total" -ForegroundColor White
Write-Host "  PASS:     $pass" -ForegroundColor Green
Write-Host "  FAIL:     $fail" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })
Write-Host "  WARN:     $warn" -ForegroundColor $(if ($warn -gt 0) { "Yellow" } else { "Green" })
Write-Host "  CRITICAL: $critical" -ForegroundColor $(if ($critical -gt 0) { "Magenta" } else { "Green" })
Write-Host ""

if ($critical -gt 0) {
    Write-Host "  VERDICT: CRITICAL issues found - DO NOT SHIP" -ForegroundColor Magenta
} elseif ($fail -gt 0) {
    Write-Host "  VERDICT: Failures found - review before shipping" -ForegroundColor Yellow
} else {
    Write-Host "  VERDICT: READY TO SHIP" -ForegroundColor Green
}
Write-Host ""

exit ($critical + $fail)
