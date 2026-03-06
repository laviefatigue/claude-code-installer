# ============================================================================
# CLAUDE CODE INSTALLER
# Download and run: irm https://your-url/install.ps1 | iex
# Or: Right-click > Run with PowerShell
# ============================================================================

param(
    [switch]$Quiet,
    [switch]$SkipVSCode,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Claude Code Installer

Usage: .\install-claude-code.ps1 [options]

Options:
  -Quiet       Skip confirmations
  -SkipVSCode  Don't install VS Code
  -Help        Show this help

"@
    exit 0
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# BANNER
# ============================================================================

Clear-Host
Write-Host @"

   _____ _                 _         _____          _
  / ____| |               | |       / ____|        | |
 | |    | | __ _ _   _  __| | ___  | |     ___   __| | ___
 | |    | |/ _`` | | | |/ _`` |/ _ \ | |    / _ \ / _`` |/ _ \
 | |____| | (_| | |_| | (_| |  __/ | |___| (_) | (_| |  __/
  \_____|_|\__,_|\__,_|\__,_|\___|  \_____\___/ \__,_|\___|

                    INSTALLER v1.0

"@ -ForegroundColor Cyan

Write-Host "  This installer will set up Claude Code on your computer.`n" -ForegroundColor White

# ============================================================================
# WHAT WILL BE INSTALLED
# ============================================================================

Write-Host "  What will be installed:" -ForegroundColor Yellow
Write-Host "  ========================" -ForegroundColor Yellow
Write-Host "  [1] VS Code          - Code editor (if not installed)" -ForegroundColor White
Write-Host "  [2] Git              - Version control (if not installed)" -ForegroundColor White
Write-Host "  [3] Claude Code CLI  - AI assistant for your terminal" -ForegroundColor White
Write-Host "  [4] Starter Skills   - /help and /getting-started commands" -ForegroundColor White
Write-Host ""

if (-not $Quiet) {
    Write-Host "  Press ENTER to continue or Ctrl+C to cancel..." -ForegroundColor Gray
    Read-Host | Out-Null
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Step {
    param($num, $msg)
    Write-Host "`n  [$num] $msg" -ForegroundColor Cyan
}

function Write-Status {
    param($msg, $status)
    $color = switch ($status) {
        "OK" { "Green" }
        "SKIP" { "Yellow" }
        "INSTALL" { "Magenta" }
        "FAIL" { "Red" }
        default { "White" }
    }
    Write-Host "      $msg " -NoNewline
    Write-Host "[$status]" -ForegroundColor $color
}

function Test-CommandExists {
    param($cmd)
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ============================================================================
# STEP 1: CHECK VS CODE
# ============================================================================

Write-Step "1/4" "Checking VS Code..."

$hasVSCode = Test-CommandExists "code"
if ($hasVSCode) {
    $version = (code --version | Select-Object -First 1)
    Write-Status "VS Code v$version" "OK"
} elseif ($SkipVSCode) {
    Write-Status "VS Code (skipped by user)" "SKIP"
} else {
    Write-Status "VS Code not found, installing..." "INSTALL"

    $hasWinget = Test-CommandExists "winget"
    if ($hasWinget) {
        winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent | Out-Null
    } else {
        $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
        $installer = Join-Path $env:TEMP "vscode-install.exe"
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList "/verysilent /mergetasks=!runcode" -Wait
        Remove-Item $installer -ErrorAction SilentlyContinue
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Test-CommandExists "code") {
        Write-Status "VS Code installed" "OK"
    } else {
        Write-Status "VS Code install may require restart" "SKIP"
    }
}

# ============================================================================
# STEP 2: CHECK GIT
# ============================================================================

Write-Step "2/4" "Checking Git..."

$hasGit = Test-CommandExists "git"
if ($hasGit) {
    $version = (git --version) -replace "git version ", ""
    Write-Status "Git v$version" "OK"
} else {
    Write-Status "Git not found, installing..." "INSTALL"

    $hasWinget = Test-CommandExists "winget"
    if ($hasWinget) {
        winget install Git.Git --accept-package-agreements --accept-source-agreements --silent | Out-Null
    } else {
        $release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
        $url = ($release.assets | Where-Object { $_.name -match "64-bit\.exe$" }).browser_download_url
        $installer = Join-Path $env:TEMP "git-install.exe"
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList "/VERYSILENT /NORESTART" -Wait
        Remove-Item $installer -ErrorAction SilentlyContinue
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Test-CommandExists "git") {
        Write-Status "Git installed" "OK"
    } else {
        Write-Status "Git install may require terminal restart" "SKIP"
    }
}

# ============================================================================
# STEP 3: INSTALL CLAUDE CODE
# ============================================================================

Write-Step "3/4" "Installing Claude Code..."

$hasClaude = Test-CommandExists "claude"
if ($hasClaude) {
    $version = (claude --version 2>$null | Select-Object -First 1)
    Write-Status "Claude Code already installed ($version)" "OK"
} else {
    Write-Status "Downloading Claude Code..." "INSTALL"

    try {
        # Use official installer
        Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1")

        # Add to PATH for this session
        $localBin = Join-Path $env:USERPROFILE ".local\bin"
        if ($env:Path -notlike "*$localBin*") {
            $env:Path = "$localBin;$env:Path"
        }

        Write-Status "Claude Code installed" "OK"
    } catch {
        Write-Status "Could not install Claude Code: $_" "FAIL"
    }
}

# ============================================================================
# STEP 4: INSTALL STARTER SKILLS
# ============================================================================

Write-Step "4/4" "Installing starter skills..."

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$skillsDir = Join-Path $claudeDir "skills"
$commandsDir = Join-Path $claudeDir "commands"

# Create directories
New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null

# Getting Started skill
$gettingStartedDir = Join-Path $skillsDir "getting-started"
New-Item -ItemType Directory -Path $gettingStartedDir -Force | Out-Null

@"
# Getting Started with Claude Code

---
name: getting-started
description: Guides new users through Claude Code basics. Activate when users ask how to get started or seem new.
user-invocable: true
allowed-tools: Read, Glob, Grep
---

## Purpose
Help new users understand what Claude Code can do.

## What to Explain

**Claude Code can help with:**

1. **Writing Code** - Just describe what you want in plain English
2. **Understanding Code** - Paste code and ask questions
3. **Working with Files** - Create, edit, search files
4. **Running Commands** - Install packages, run tests, etc.

## Quick Tips
- Be specific about what you want
- Share error messages when asking for help
- Ask follow-up questions if needed

## End with
> "What would you like to work on? Just describe it and I'll help!"
"@ | Set-Content (Join-Path $gettingStartedDir "SKILL.md")

Write-Status "Skill: /getting-started" "OK"

# Help command
@"
# Claude Code Help

## Quick Commands
| Command | Description |
|---------|-------------|
| /getting-started | New here? Start with this |
| /help | Show this help |

## What Can Claude Code Do?
- Write and explain code
- Create and edit files
- Run terminal commands
- Debug errors

## Tips
1. Be specific about what you want
2. Share error messages
3. Ask follow-up questions
"@ | Set-Content (Join-Path $commandsDir "help.md")

Write-Status "Command: /help" "OK"

# ============================================================================
# AUTHENTICATION
# ============================================================================

Write-Host "`n  --------------------------------------------------------" -ForegroundColor Gray
Write-Host "  AUTHENTICATION REQUIRED" -ForegroundColor Yellow
Write-Host "  --------------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "  Claude Code requires an Anthropic account." -ForegroundColor White
Write-Host "  (Claude Pro, Max, or Teams subscription needed)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Opening your browser to sign in..." -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

try {
    Start-Process "claude"
} catch {
    Write-Host "  Could not start Claude Code automatically." -ForegroundColor Yellow
    Write-Host "  Please open a new terminal and run: claude" -ForegroundColor Yellow
}

Write-Host "  After signing in, press ENTER to continue..." -ForegroundColor Gray
Read-Host | Out-Null

# ============================================================================
# COMPLETE
# ============================================================================

Write-Host @"

  ========================================================
                    INSTALLATION COMPLETE!
  ========================================================

  To start using Claude Code:

    1. Open VS Code
    2. Press Ctrl+` to open terminal
    3. Type: claude
    4. Start chatting!

  Try these commands:
    /help             - See available commands
    /getting-started  - Interactive tutorial

  ========================================================

"@ -ForegroundColor Green

if (-not $Quiet) {
    $open = Read-Host "  Open VS Code now? (Y/n)"
    if ($open -ne "n" -and $open -ne "N") {
        Start-Process "code" -ErrorAction SilentlyContinue
    }
}

Write-Host "`n  Enjoy Claude Code!`n" -ForegroundColor Cyan
