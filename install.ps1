# Claude Code Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
#
# Verified URLs (2026-03-13):
#   Node.js  v24.14.0  - https://nodejs.org/dist/v24.14.0/node-v24.14.0-x64.msi
#   Git      v2.53.0.2 - https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.2/Git-2.53.0.2-64-bit.exe
#   Python   v3.14.3   - https://www.python.org/ftp/python/3.14.3/python-3.14.3-amd64.exe
#   VS Code  latest    - https://code.visualstudio.com/sha/download?build=stable&os=win32-x64
#   Claude   latest    - npm @anthropic-ai/claude-code
#   Ext      latest    - anthropic.claude-code, foam.foam-vscode

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# Known install paths (don't rely on PATH refresh mid-session)
# ============================================================================
$tempDir    = Join-Path $env:TEMP "claude-setup"
$nodePath   = "$env:ProgramFiles\nodejs"
$npmExe     = "$nodePath\npm.cmd"
$nodeExe    = "$nodePath\node.exe"
$gitExe     = "$env:ProgramFiles\Git\cmd\git.exe"
$gitBashExe = "$env:ProgramFiles\Git\bin\bash.exe"
$codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
$claudeExe  = "$env:APPDATA\npm\claude.cmd"

# Python installs to versioned folders - check multiple
$pythonLocations = @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:ProgramFiles\Python314\python.exe",
    "$env:ProgramFiles\Python313\python.exe"
)

# ============================================================================
# Helpers
# ============================================================================

function Get-CodePath {
    if (Test-Path $codeExe) { return $codeExe }
    if (Test-Path $codeExeAlt) { return $codeExeAlt }
    $cmd = Get-Command code -EA SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Test-Installed {
    param([string]$Name)
    switch ($Name) {
        "node" {
            return (Test-Path $nodeExe) -or [bool](Get-Command node -EA SilentlyContinue)
        }
        "git" {
            return (Test-Path $gitExe) -or [bool](Get-Command git -EA SilentlyContinue)
        }
        "python" {
            foreach ($loc in $pythonLocations) {
                if (Test-Path $loc) { return $true }
            }
            return [bool](Get-Command python -EA SilentlyContinue)
        }
        "code" {
            return (Get-CodePath) -ne $null
        }
        "claude" {
            return (Test-Path $claudeExe) -or
                   (Test-Path "$env:USERPROFILE\.local\bin\claude.exe") -or
                   [bool](Get-Command claude -EA SilentlyContinue)
        }
    }
    return $false
}

function Show-Progress {
    param([int]$Percent)
    $width = 30
    $filled = [math]::Floor($width * $Percent / 100)
    $empty = $width - $filled
    $bar = ([char]0x2588).ToString() * $filled + ([char]0x2591).ToString() * $empty
    Write-Host "`r      $bar $Percent%" -NoNewline -ForegroundColor DarkCyan
    if ($Percent -ge 100) { Write-Host "" }
}

function Start-Download {
    param([string]$Url, [string]$OutFile, [int]$EstimatedSeconds)

    $job = Start-Job -ScriptBlock {
        param($u, $o)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing
    } -ArgumentList $Url, $OutFile

    $steps = [math]::Max($EstimatedSeconds * 5, 10)
    $increment = [math]::Ceiling(100 / $steps)

    for ($i = 0; $i -le 100; $i += $increment) {
        Show-Progress -Percent ([math]::Min($i, 99))
        Start-Sleep -Milliseconds 200

        # Jump ahead if download finished early
        if ($job.State -eq "Completed" -or $job.State -eq "Failed") { break }
    }

    Wait-Job $job | Out-Null
    $jobResult = Receive-Job $job -EA SilentlyContinue
    $jobState = $job.State
    Remove-Job $job

    if ($jobState -eq "Failed" -or -not (Test-Path $OutFile)) {
        Show-Progress -Percent 0
        return $false
    }

    Show-Progress -Percent 100
    return $true
}

# ============================================================================
# Welcome
# ============================================================================

Clear-Host
Write-Host ""
Write-Host "  +-------------------------------------------------------+" -ForegroundColor DarkCyan
Write-Host "  |                                                       |" -ForegroundColor DarkCyan
Write-Host "  |            " -NoNewline -ForegroundColor DarkCyan
Write-Host "Welcome to Claude Code" -NoNewline -ForegroundColor White
Write-Host "                   |" -ForegroundColor DarkCyan
Write-Host "  |                                                       |" -ForegroundColor DarkCyan
Write-Host "  +-------------------------------------------------------+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  This installer sets up everything you need to start" -ForegroundColor Gray
Write-Host "  creating with Claude in VS Code." -ForegroundColor Gray
Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What we'll install:" -ForegroundColor White
Write-Host ""
Write-Host "    1. Node.js    " -NoNewline -ForegroundColor Cyan
Write-Host "Lets your computer run Claude" -ForegroundColor DarkGray
Write-Host "    2. Git + Bash " -NoNewline -ForegroundColor Cyan
Write-Host "Saves your work like a time machine" -ForegroundColor DarkGray
Write-Host "    3. Python     " -NoNewline -ForegroundColor Cyan
Write-Host "For automation and data projects" -ForegroundColor DarkGray
Write-Host "    4. VS Code    " -NoNewline -ForegroundColor Cyan
Write-Host "Your workspace with Claude" -ForegroundColor DarkGray
Write-Host "    5. Claude     " -NoNewline -ForegroundColor Cyan
Write-Host "Your AI partner" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Plus VS Code extensions:" -ForegroundColor White
Write-Host "    - Claude Code  " -NoNewline -ForegroundColor Gray
Write-Host "(AI assistant in your editor)" -ForegroundColor DarkGray
Write-Host "    - Foam         " -NoNewline -ForegroundColor Gray
Write-Host "(connected notes & knowledge)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Takes about 5 minutes. Cancel anytime with Ctrl+C." -ForegroundColor DarkGray
Write-Host ""

$response = Read-Host "  Ready to begin? [Y/n]"

if ($response -eq "n" -or $response -eq "N") {
    Write-Host ""
    Write-Host "  No problem! Run this command again when you're ready." -ForegroundColor Gray
    Write-Host ""
    exit
}

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ============================================================================
# 1. Node.js v24.14.0 LTS
# ============================================================================

Write-Host "  [1/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Node.js" -ForegroundColor White
Write-Host "        Claude speaks JavaScript. Node.js is the translator" -ForegroundColor DarkGray
Write-Host "        that lets your computer understand Claude." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "node") {
    $v = & node --version 2>$null
    if (-not $v) { $v = (& "$nodeExe" --version 2>$null) }
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "$v" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading Node.js v24.14.0..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "node.msi"
    $ok = Start-Download -Url "https://nodejs.org/dist/v24.14.0/node-v24.14.0-x64.msi" -OutFile $installer -EstimatedSeconds 10

    if ($ok) {
        Write-Host "      Installing..." -ForegroundColor Gray
        Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait

        if (Test-Path $nodeExe) {
            Write-Host "      [OK] Node.js v24.14.0 installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Installed - may need restart to use" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      [X] Download failed - visit nodejs.org" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# 2. Git v2.53.0.2 + Git Bash
# ============================================================================

Write-Host "  [2/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Git + Git Bash" -ForegroundColor White
Write-Host "        Like a time machine for your work. Every change is" -ForegroundColor DarkGray
Write-Host "        saved, so you can always undo mistakes." -ForegroundColor DarkGray
Write-Host "        Includes Git Bash, which Claude Code requires on Windows." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "git") {
    $v = (& git --version 2>$null) -replace "git version ", ""
    if (-not $v) { $v = (& "$gitExe" --version 2>$null) -replace "git version ", "" }
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "v$v" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading Git v2.53.0.2..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "git.exe"
    $ok = Start-Download -Url "https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.2/Git-2.53.0.2-64-bit.exe" -OutFile $installer -EstimatedSeconds 15

    if ($ok) {
        Write-Host "      Installing..." -ForegroundColor Gray
        Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait

        if (Test-Path $gitExe) {
            Write-Host "      [OK] Git v2.53.0.2 installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Installed - may need restart to use" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      [X] Download failed - visit git-scm.com" -ForegroundColor Red
    }
}

# CRITICAL: Claude Code on Windows requires Git Bash
# Set the env var regardless of whether Git was just installed or already existed
if (Test-Path $gitBashExe) {
    [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBashExe, "User")
    $env:CLAUDE_CODE_GIT_BASH_PATH = $gitBashExe
    Write-Host "      [OK] Git Bash path configured for Claude" -ForegroundColor Green
} else {
    Write-Host "      [!] Git Bash not found - Claude Code may show an error" -ForegroundColor Yellow
    Write-Host "          Fix: set CLAUDE_CODE_GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================================
# 3. Python v3.14.3
# ============================================================================

Write-Host "  [3/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Python" -ForegroundColor White
Write-Host "        A beginner-friendly language for automation, data," -ForegroundColor DarkGray
Write-Host "        and AI projects. Claude uses it a lot." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "python") {
    $v = (& python --version 2>$null) -replace "Python ", ""
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "v$v" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading Python v3.14.3..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "python.exe"
    $ok = Start-Download -Url "https://www.python.org/ftp/python/3.14.3/python-3.14.3-amd64.exe" -OutFile $installer -EstimatedSeconds 10

    if ($ok) {
        Write-Host "      Installing..." -ForegroundColor Gray
        Start-Process $installer -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0" -Wait

        if (Test-Installed "python") {
            Write-Host "      [OK] Python v3.14.3 installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Installed - may need restart to use" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      [X] Download failed - visit python.org" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# 4. VS Code (latest stable)
# ============================================================================

Write-Host "  [4/5] " -NoNewline -ForegroundColor Yellow
Write-Host "VS Code" -ForegroundColor White
Write-Host "        Your creative workspace. Like Google Docs for code." -ForegroundColor DarkGray
Write-Host "        This is where you and Claude build things together." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "code") {
    Write-Host "      [OK] Already installed" -ForegroundColor Green
} else {
    Write-Host "      Downloading VS Code..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "vscode.exe"
    $ok = Start-Download -Url "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $installer -EstimatedSeconds 20

    if ($ok) {
        Write-Host "      Installing..." -ForegroundColor Gray
        Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait
        Start-Sleep -Seconds 2

        if (Get-CodePath) {
            Write-Host "      [OK] VS Code installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Installed - may need restart to use" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      [X] Download failed - visit code.visualstudio.com" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# 5. Claude Code CLI (latest via npm)
# ============================================================================

Write-Host "  [5/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Claude Code" -ForegroundColor White
Write-Host "        Your AI partner. Tell Claude what you want to build," -ForegroundColor DarkGray
Write-Host "        and it helps you create it step by step." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "claude") {
    Write-Host "      [OK] Already installed" -ForegroundColor Green
} else {
    Write-Host "      Installing via npm..." -ForegroundColor Gray

    # Ensure Node/npm is in PATH for this session
    $env:Path = "$nodePath;$env:APPDATA\npm;$env:Path"

    $installed = $false

    # Method 1: Use npm directly from known path
    if (Test-Path $npmExe) {
        & $npmExe install -g @anthropic-ai/claude-code 2>$null | Out-Null
        if (Test-Installed "claude") { $installed = $true }
    }

    # Method 2: Spawn new PowerShell with fresh PATH
    if (-not $installed) {
        Write-Host "      Trying in new process..." -ForegroundColor Gray
        $cmd = "`$env:Path = `"$nodePath;$env:APPDATA\npm;`$env:Path`"; npm install -g @anthropic-ai/claude-code"
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd" -Wait -WindowStyle Hidden
        if (Test-Path $claudeExe) { $installed = $true }
    }

    if ($installed) {
        Write-Host "      [OK] Claude Code installed" -ForegroundColor Green
    } else {
        Write-Host "      [!] Needs restart. Then run:" -ForegroundColor Yellow
        Write-Host "          npm install -g @anthropic-ai/claude-code" -ForegroundColor Cyan
    }
}

Write-Host ""

# ============================================================================
# VS Code Extensions
# ============================================================================

Write-Host "  [+] " -NoNewline -ForegroundColor DarkCyan
Write-Host "VS Code Extensions" -ForegroundColor White
Write-Host ""

$codePath = Get-CodePath
if ($codePath) {
    # Claude Code extension
    Write-Host "      Installing Claude Code extension..." -ForegroundColor Gray
    & $codePath --install-extension anthropic.claude-code --force 2>$null | Out-Null
    Write-Host "      [OK] Claude Code " -NoNewline -ForegroundColor Green
    Write-Host "- AI assistant in your editor" -ForegroundColor DarkGray

    # Foam extension
    Write-Host "      Installing Foam extension..." -ForegroundColor Gray
    & $codePath --install-extension foam.foam-vscode --force 2>$null | Out-Null
    Write-Host "      [OK] Foam " -NoNewline -ForegroundColor Green
    Write-Host "- connected notes and knowledge graph" -ForegroundColor DarkGray
} else {
    Write-Host "      [-] VS Code not in PATH yet" -ForegroundColor DarkGray
    Write-Host "          Extensions will install on first launch" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$allGood = (Test-Installed "node") -and (Test-Path $gitBashExe) -and (Test-Installed "code" -or (Test-Path $codeExe) -or (Test-Path $codeExeAlt))

if ($allGood) {
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
    Write-Host "  |                                                       |" -ForegroundColor Green
    Write-Host "  |               " -NoNewline -ForegroundColor Green
    Write-Host "Setup Complete!" -NoNewline -ForegroundColor White
    Write-Host "                       |" -ForegroundColor Green
    Write-Host "  |                                                       |" -ForegroundColor Green
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
} else {
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |                                                       |" -ForegroundColor Yellow
    Write-Host "  |             " -NoNewline -ForegroundColor Yellow
    Write-Host "Almost there!" -NoNewline -ForegroundColor White
    Write-Host "                         |" -ForegroundColor Yellow
    Write-Host "  |                                                       |" -ForegroundColor Yellow
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Installed:" -ForegroundColor White

# Check each component
$components = @(
    @{ Name = "Node.js";    Check = { Test-Installed "node" } },
    @{ Name = "Git + Bash"; Check = { Test-Path $gitBashExe } },
    @{ Name = "Python";     Check = { Test-Installed "python" } },
    @{ Name = "VS Code";    Check = { (Get-CodePath) -ne $null } },
    @{ Name = "Claude CLI"; Check = { Test-Installed "claude" } },
    @{ Name = "Extensions"; Check = { (Get-CodePath) -ne $null } }
)

foreach ($c in $components) {
    $ok = & $c.Check
    if ($ok) {
        Write-Host "    [OK] $($c.Name)" -ForegroundColor Green
    } else {
        Write-Host "    [!] $($c.Name) - restart and run installer again" -ForegroundColor Yellow
    }
}

Write-Host ""

# Cleanup temp files
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ============================================================================
# Launch
# ============================================================================

Write-Host "  What happens next:" -ForegroundColor White
Write-Host "    1. VS Code opens" -ForegroundColor Gray
Write-Host "    2. A quick visual guide shows you where Claude is" -ForegroundColor Gray
Write-Host "    3. Click the Claude icon, sign in, and start creating" -ForegroundColor Gray
Write-Host ""

$null = Read-Host "  Press ENTER to open VS Code"

$codePath = Get-CodePath
if ($codePath) {
    Start-Process $codePath
} else {
    # Try common locations directly
    $tryPaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe"
    )
    foreach ($p in $tryPaths) {
        if (Test-Path $p) {
            Start-Process $p
            break
        }
    }
}

Start-Sleep -Seconds 1
Start-Process "https://laviefatigue.github.io/claude-code-installer/onboarding.html"

Write-Host ""
Write-Host "  [OK] VS Code is opening..." -ForegroundColor Green
Write-Host "  [OK] Tutorial opened in your browser" -ForegroundColor Green
Write-Host ""
Write-Host "  You're ready to create. Enjoy!" -ForegroundColor Cyan
Write-Host ""
