# Claude Code Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Step { param($n, $t, $s) Write-Host "`n  [$n/8] $t" -ForegroundColor Cyan; Write-Host "  $s" -ForegroundColor Gray }
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
    - VS Code + Extensions
      - Claude Code extension
      - Foam (knowledge graph)
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

# 2. Claude Code CLI
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
Write-Step "3" "VS Code" "Code editor"
$vscodeInstalled = Get-Command code -ErrorAction SilentlyContinue
if ($vscodeInstalled) {
    Write-Ok "Already installed"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) {
        Write-Ok " Done"
        # Refresh PATH to find code command
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        $vscodeInstalled = $true
    } else {
        Write-Skip " Skipped"
    }
}

# 4. VS Code Extensions
Write-Step "4" "VS Code Extensions" "Claude Code + Foam"
if (Get-Command code -ErrorAction SilentlyContinue) {
    # Claude Code extension
    $extensions = code --list-extensions 2>$null

    if ($extensions -contains "anthropic.claude-code") {
        Write-Ok "Claude Code extension: installed"
    } else {
        Write-Host "       Installing Claude Code extension..." -NoNewline
        code --install-extension anthropic.claude-code --force 2>$null
        if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
    }

    # Foam extension
    if ($extensions -contains "foam.foam-vscode") {
        Write-Ok "Foam extension: installed"
    } else {
        Write-Host "       Installing Foam extension..." -NoNewline
        code --install-extension foam.foam-vscode --force 2>$null
        if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
    }
} else {
    Write-Skip "VS Code not available - skipping extensions"
}

# 5. Node.js
Write-Step "5" "Node.js" "JavaScript runtime"
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node --version)
    Write-Ok "Already installed: $v"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
}

# 6. Python
Write-Step "6" "Python" "Python runtime"
if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = (python --version)
    Write-Ok "Already installed: $v"
} else {
    Write-Host "       Installing..." -NoNewline
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent 2>$null
    if ($?) { Write-Ok " Done" } else { Write-Skip " Skipped" }
}

# 7. Starter skills
Write-Step "7" "Starter Skills" "/help and /getting-started commands"

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

# 8. Authentication
Write-Step "8" "Sign In" "Connect to Anthropic"

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

  What was installed:
    - Git for Windows
    - Claude Code CLI
    - VS Code + Claude Code extension + Foam
    - Node.js
    - Python
    - Starter skills

  To use Claude Code:
    1. Open VS Code
    2. Press Ctrl+` to open terminal
    3. Type: claude
    4. Start chatting!

  ==========================================

"@ -ForegroundColor Green
