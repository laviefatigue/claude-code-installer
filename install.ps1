# Claude Code Framework Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# Output Helpers (PowerShell-native colors that work everywhere)
# ============================================================================

function Write-Logo {
    Write-Host ""
    Write-Host "    =============================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "       Claude Code Framework" -ForegroundColor White
    Write-Host ""
    Write-Host "       Your creative journey begins." -ForegroundColor Gray
    Write-Host ""
    Write-Host "    =============================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step {
    param(
        [string]$Number,
        [string]$Name,
        [string]$Metaphor,
        [string]$Why
    )
    Write-Host ""
    Write-Host "  [$Number] " -NoNewline -ForegroundColor DarkYellow
    Write-Host "$Metaphor" -ForegroundColor White
    Write-Host "      $Name" -ForegroundColor Gray
    if ($Why) {
        Write-Host "      $Why" -ForegroundColor DarkGray
    }
}

function Write-OK {
    param([string]$Message, [string]$Detail)
    if ($Detail) {
        Write-Host "      [OK] " -NoNewline -ForegroundColor Green
        Write-Host "$Message " -NoNewline -ForegroundColor White
        Write-Host "($Detail)" -ForegroundColor DarkGray
    } else {
        Write-Host "      [OK] " -NoNewline -ForegroundColor Green
        Write-Host "$Message" -ForegroundColor White
    }
}

function Write-Already {
    param([string]$Message, [string]$Version)
    Write-Host "      [OK] " -NoNewline -ForegroundColor Green
    Write-Host "$Message " -NoNewline -ForegroundColor White
    if ($Version) {
        Write-Host "$Version" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }
}

function Write-Skip {
    param([string]$Message)
    Write-Host "      [--] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$Message" -ForegroundColor DarkGray
}

function Write-Problem {
    param([string]$Message)
    Write-Host "      [!!] " -NoNewline -ForegroundColor Yellow
    Write-Host "$Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "      [X]  " -NoNewline -ForegroundColor Red
    Write-Host "$Message" -ForegroundColor Red
}

# ============================================================================
# Main Installation
# ============================================================================

Clear-Host
Write-Logo

Write-Host "  We're about to set up your creative toolkit." -ForegroundColor Gray
Write-Host "  This usually takes 2-5 minutes." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What's included:" -ForegroundColor White
Write-Host ""
Write-Host "    - Claude Code CLI    " -NoNewline -ForegroundColor Cyan
Write-Host "(the AI assistant)" -ForegroundColor DarkGray
Write-Host "    - VS Code + Extensions" -NoNewline -ForegroundColor Cyan
Write-Host " (your editor)" -ForegroundColor DarkGray
Write-Host "    - Git                " -NoNewline -ForegroundColor Cyan
Write-Host "(version control)" -ForegroundColor DarkGray
Write-Host "    - Node.js            " -NoNewline -ForegroundColor Cyan
Write-Host "(JavaScript runtime)" -ForegroundColor DarkGray
Write-Host "    - Python             " -NoNewline -ForegroundColor Cyan
Write-Host "(optional)" -ForegroundColor DarkGray
Write-Host "    - Starter skills     " -NoNewline -ForegroundColor Cyan
Write-Host "(/help, /getting-started)" -ForegroundColor DarkGray
Write-Host ""

$null = Read-Host "  Press ENTER to begin"

$results = @{
    Installed = @()
    Skipped   = @()
    Failed    = @()
}

# ----------------------------------------------------------------------------
# 1. Git - "The Memory"
# ----------------------------------------------------------------------------

Write-Step -Number "1/7" -Name "Installing Git" -Metaphor "Preparing your Memory" `
    -Why "Tracks every change you make. Never lose work."

if (Get-Command git -ErrorAction SilentlyContinue) {
    $v = (git --version) -replace "git version ", ""
    Write-Already "Git ready" "v$v"
    $results.Installed += "Git"
} else {
    try {
        winget install Git.Git --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-OK "Git installed" "Memory ready"
        $results.Installed += "Git"
    } catch {
        Write-Fail "Git failed - visit git-scm.com to install manually"
        $results.Failed += "Git"
    }
}

# ----------------------------------------------------------------------------
# 2. Node.js - "The Heartbeat"
# ----------------------------------------------------------------------------

Write-Step -Number "2/7" -Name "Installing Node.js" -Metaphor "Igniting the Heartbeat" `
    -Why "The engine that powers Claude Code."

if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node --version)
    Write-Already "Node.js ready" "$v"
    $results.Installed += "Node.js"
} else {
    try {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-OK "Node.js installed" "Heartbeat strong"
        $results.Installed += "Node.js"
    } catch {
        Write-Fail "Node.js failed"
        $results.Failed += "Node.js"
    }
}

# ----------------------------------------------------------------------------
# 3. Python - "The Serpent" (Optional)
# ----------------------------------------------------------------------------

Write-Step -Number "3/7" -Name "Installing Python" -Metaphor "Summoning ancient wisdom" `
    -Why "A versatile language for data science and automation. (Optional)"

if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = (python --version) -replace "Python ", ""
    Write-Already "Python ready" "v$v"
    $results.Installed += "Python"
} else {
    try {
        winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-OK "Python installed"
        $results.Installed += "Python"
    } catch {
        Write-Skip "Python skipped - that's okay, it's optional"
        $results.Skipped += "Python"
    }
}

# ----------------------------------------------------------------------------
# 4. Claude Code CLI - "The Voice"
# ----------------------------------------------------------------------------

Write-Step -Number "4/7" -Name "Installing Claude Code CLI" -Metaphor "Awakening the Voice" `
    -Why "The heart of the experience. Your AI coding companion."

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Already "Claude Code ready"
    $results.Installed += "Claude Code CLI"
} else {
    try {
        Write-Host "      Installing..." -ForegroundColor DarkGray
        Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1")
        $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
        Write-OK "Claude Code installed" "The Voice is ready"
        $results.Installed += "Claude Code CLI"
    } catch {
        Write-Fail "Claude Code failed - visit claude.ai/code for manual install"
        $results.Failed += "Claude Code CLI"
    }
}

# ----------------------------------------------------------------------------
# 5. VS Code - "The Canvas"
# ----------------------------------------------------------------------------

Write-Step -Number "5/7" -Name "Installing VS Code" -Metaphor "Opening your Canvas" `
    -Why "A powerful editor where you'll write and organize projects."

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Already "VS Code ready"
    $results.Installed += "VS Code"
} else {
    try {
        winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-OK "VS Code installed" "Canvas prepared"
        $results.Installed += "VS Code"
    } catch {
        Write-Problem "VS Code failed - visit code.visualstudio.com"
        $results.Failed += "VS Code"
    }
}

# ----------------------------------------------------------------------------
# 6. VS Code Extensions - "The Bridge & Web"
# ----------------------------------------------------------------------------

Write-Step -Number "6/7" -Name "Installing Extensions" -Metaphor "Building the Bridge" `
    -Why "Claude extension + Foam for connected notes."

if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensions = code --list-extensions 2>$null

    # Claude extension
    if ($extensions -contains "anthropic.claude-code") {
        Write-Already "Claude extension ready"
    } else {
        try {
            code --install-extension anthropic.claude-code --force 2>$null | Out-Null
            Write-OK "Claude extension installed"
        } catch {
            Write-Problem "Claude extension failed - install from VS Code marketplace"
        }
    }
    $results.Installed += "Claude Extension"

    # Foam extension
    if ($extensions -contains "foam.foam-vscode") {
        Write-Already "Foam extension ready"
    } else {
        try {
            code --install-extension foam.foam-vscode --force 2>$null | Out-Null
            Write-OK "Foam extension installed"
        } catch {
            Write-Skip "Foam skipped - optional"
        }
    }
    $results.Installed += "Foam"
} else {
    Write-Skip "VS Code not available - skipping extensions"
    $results.Skipped += "Extensions"
}

# ----------------------------------------------------------------------------
# 7. Starter Skills - "The Scrolls"
# ----------------------------------------------------------------------------

Write-Step -Number "7/7" -Name "Installing starter skills" -Metaphor "Unrolling the Scrolls" `
    -Why "Commands like /help and /getting-started."

$skillsDir = "$env:USERPROFILE\.claude\skills\getting-started"
$commandsDir = "$env:USERPROFILE\.claude\commands"

try {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null

    @"
# Getting Started

---
name: getting-started
description: New user guide for Claude Code
user-invocable: true
---

Welcome to Claude Code! Here's what you can do:

## Write & Edit Code
Ask Claude to write functions, fix bugs, or refactor code.

## Navigate Your Codebase
Claude can read files, search for patterns, and understand your project.

## Run Commands
Execute terminal commands, run tests, and manage your workflow.

## Tips
1. Be specific - "Add error handling to login()" beats "fix the code"
2. Share context - mention the file or error message
3. Iterate - Claude learns from your feedback
"@ | Set-Content "$skillsDir\SKILL.md" -Encoding UTF8

    @"
# Help

Type /getting-started for a guided tour.

## What Claude Code Can Do
- Write and explain code
- Create and edit files
- Run terminal commands
- Debug errors
- Answer questions about your codebase

## Learn More
https://github.com/anthropics/claude-code
"@ | Set-Content "$commandsDir\help.md" -Encoding UTF8

    Write-OK "Skills installed" "/help and /getting-started ready"
    $results.Installed += "Starter Skills"
} catch {
    Write-Problem "Skills setup failed"
    $results.Failed += "Starter Skills"
}

# ============================================================================
# Completion
# ============================================================================

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""
Write-Host "     Your toolkit is ready." -ForegroundColor White
Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""

# Summary
foreach ($item in $results.Installed) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "$item" -ForegroundColor White
}
foreach ($item in $results.Skipped) {
    Write-Host "  [--] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$item (optional)" -ForegroundColor DarkGray
}
foreach ($item in $results.Failed) {
    Write-Host "  [X]  " -NoNewline -ForegroundColor Red
    Write-Host "$item - needs attention" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  NEXT: Watch the 2-minute visual guide" -ForegroundColor White
Write-Host ""
Write-Host "  We'll open VS Code and the tutorial." -ForegroundColor Gray
Write-Host "  Follow along to learn where everything is." -ForegroundColor Gray
Write-Host ""
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$onboardingUrl = "https://laviefatigue.github.io/claude-code-installer/onboarding.html"

$launch = Read-Host "  Press ENTER to continue (or type 'skip')"
if ($launch -ne "skip") {
    Write-Host ""
    Write-Host "  Opening VS Code..." -ForegroundColor Gray

    # Open VS Code
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Start-Process "code"
    }

    Start-Sleep -Seconds 1

    Write-Host "  Opening visual guide..." -ForegroundColor Gray
    Start-Process $onboardingUrl

    Write-Host ""
    Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  The guide will show you:" -ForegroundColor White
    Write-Host "    - Where to find Claude in VS Code" -ForegroundColor Gray
    Write-Host "    - How to sign in" -ForegroundColor Gray
    Write-Host "    - How to start your first conversation" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Guide URL (bookmark this!):" -ForegroundColor DarkGray
    Write-Host "  $onboardingUrl" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "  What will you create?" -ForegroundColor Yellow
Write-Host ""
