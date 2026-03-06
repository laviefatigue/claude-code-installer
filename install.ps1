# Claude Code Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step { param($n, $t, $s) Write-Host "`n  [$n/6] $t" -ForegroundColor Cyan; Write-Host "  $s" -ForegroundColor Gray }
function Write-Ok { param($m) Write-Host "       $m" -ForegroundColor Green }
function Write-Skip { param($m) Write-Host "       $m" -ForegroundColor Yellow }
function Write-Err { param($m) Write-Host "       $m" -ForegroundColor Red }

Clear-Host
Write-Host @"

  ==========================================
        CLAUDE CODE INSTALLER
  ==========================================

  This will install:

    REQUIRED
    - Git for Windows (runs terminal commands)
    - Claude Code CLI (the AI assistant)

    RECOMMENDED
    - VS Code (code editor)
    - Node.js (JavaScript runtime)
    - Python (Python runtime)
    - Starter skills (/help, /getting-started)

  ==========================================

"@ -ForegroundColor White

Read-Host "  Press ENTER to start"

# 1. Git
Write-Step "1" "Git for Windows" "Required - Claude Code uses Git Bash"
if (Get-Command git -ErrorAction SilentlyContinue) {
    $v = (git --version) -replace "git version ", ""
    Write-Ok "Already installed: $v"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install Git.Git --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Err " Failed - install manually: https://git-scm.com" }
}

# 2. Claude Code
Write-Step "2" "Claude Code CLI" "Required - The AI assistant"
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Ok "Already installed"
} else {
    Write-Host "       Installing..." -NoNewline
    try {
        Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1")
        $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
        Write-Ok " Done"
    } catch {
        Write-Err " Failed: $_"
    }
}

# 3. VS Code
Write-Step "3" "VS Code" "Recommended - Best editor for Claude Code"
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Ok "Already installed"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
}

# 4. Node.js
Write-Step "4" "Node.js" "Recommended - JavaScript runtime"
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node --version)
    Write-Ok "Already installed: $v"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
}

# 5. Python
Write-Step "5" "Python" "Recommended - Python runtime"
if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = (python --version)
    Write-Ok "Already installed: $v"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
}

# 6. Starter skills
Write-Step "6" "Starter Skills" "/help and /getting-started commands"

$skillsDir = "$env:USERPROFILE\.claude\skills\getting-started"
$commandsDir = "$env:USERPROFILE\.claude\commands"

New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null

@"
# Getting Started

---
name: getting-started
description: New user guide for Claude Code
user-invocable: true
---

Help new users understand what Claude Code can do: write code, edit files, run commands, and more.
"@ | Set-Content "$skillsDir\SKILL.md"

@"
# Help

Type /getting-started for a tutorial.

## What Claude Code Can Do
- Write and explain code
- Create and edit files
- Run terminal commands
- Debug errors
"@ | Set-Content "$commandsDir\help.md"

Write-Ok "Installed"

# Auth
Write-Host @"

  ==========================================
        SIGN IN TO ANTHROPIC
  ==========================================

  Opening Claude Code...
  Sign in with your Claude Pro, Max, or Teams account.

"@ -ForegroundColor White

Start-Sleep -Seconds 2
Start-Process "claude" -ErrorAction SilentlyContinue

Write-Host @"

  ==========================================
        INSTALLATION COMPLETE!
  ==========================================

  To use Claude Code:
    1. Open any terminal (PowerShell, VS Code, etc.)
    2. Type: claude
    3. Start chatting!

  ==========================================

"@ -ForegroundColor Green
