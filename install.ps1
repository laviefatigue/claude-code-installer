# Claude Code Framework Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════════════════════
# Color Palette (matches terminal-messages.md)
# ═══════════════════════════════════════════════════════════════════════════════

$script:Colors = @{
    Gold   = "`e[38;5;221m"
    Sage   = "`e[38;5;114m"
    Coral  = "`e[38;5;210m"
    Sand   = "`e[38;5;223m"
    Cream  = "`e[38;5;230m"
    Dim    = "`e[2m"
    Bold   = "`e[1m"
    Reset  = "`e[0m"
}

$C = $script:Colors

# Symbols
$Check   = [char]0x2713  # ✓
$Arrow   = [char]0x2192  # →
$Sparkle = [char]0x2726  # ✦
$Dot     = [char]0x00B7  # ·

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════════

function Write-Welcome {
    Clear-Host
    Write-Host ""
    Write-Host "$($C.Cream)$($C.Bold)"
    Write-Host "    ┌─────────────────────────────────────────┐"
    Write-Host "    │                                         │"
    Write-Host "    │      Claude Code Framework              │"
    Write-Host "    │                                         │"
    Write-Host "    │      Your creative journey begins.      │"
    Write-Host "    │                                         │"
    Write-Host "    └─────────────────────────────────────────┘"
    Write-Host "$($C.Reset)"
    Write-Host ""
    Write-Host "$($C.Sand)We're about to set up your creative toolkit.$($C.Reset)"
    Write-Host "$($C.Dim)This usually takes 2-5 minutes.$($C.Reset)"
    Write-Host ""
}

function Write-Installing {
    param($Name, $Metaphor, $Why)
    Write-Host ""
    Write-Host "$($C.Gold)$Sparkle$($C.Reset) $($C.Cream)$Metaphor...$($C.Reset)"
    Write-Host "$($C.Dim)   $Name$($C.Reset)"
    if ($Why) {
        Write-Host "$($C.Dim)   $Why$($C.Reset)"
    }
}

function Write-Success {
    param($Message, $Detail)
    if ($Detail) {
        Write-Host "$($C.Sage)$Check$($C.Reset) $($C.Sand)$Message $($C.Dim)($Detail)$($C.Reset)"
    } else {
        Write-Host "$($C.Sage)$Check$($C.Reset) $($C.Sand)$Message$($C.Reset)"
    }
}

function Write-AlreadyInstalled {
    param($Message, $Version)
    if ($Version) {
        Write-Host "$($C.Sage)$Check$($C.Reset) $($C.Sand)$Message $($C.Dim)$Version$($C.Reset)"
    } else {
        Write-Host "$($C.Sage)$Check$($C.Reset) $($C.Sand)$Message$($C.Reset)"
    }
}

function Write-Skipped {
    param($Message)
    Write-Host "$($C.Dim)$Dot $Message$($C.Reset)"
}

function Write-Problem {
    param($Message)
    Write-Host "$($C.Coral)$Dot$($C.Reset) $($C.Sand)$Message$($C.Reset)"
}

function Write-Progress {
    param($Current, $Total)
    $pct = [math]::Round(($Current / $Total) * 100)
    $filled = [math]::Round($pct / 5)
    $empty = 20 - $filled
    $bar = "$($C.Gold)[" + ("█" * $filled) + ("░" * $empty) + "]$($C.Reset) $pct%"
    Write-Host "`r$bar" -NoNewline
}

function Write-SectionComplete {
    param($Title)
    Write-Host ""
    Write-Host "$($C.Cream)$($C.Bold)$Title$($C.Reset)"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Installation
# ═══════════════════════════════════════════════════════════════════════════════

Write-Welcome
Write-Host "$($C.Gold)$Arrow$($C.Reset) $($C.Sand)Preparing your workspace...$($C.Reset)"
Write-Host ""
Read-Host "  Press ENTER to begin"

$results = @{
    Installed = @()
    Skipped   = @()
    Failed    = @()
}

# ───────────────────────────────────────────────────────────────────────────────
# 1. Git — The Memory
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing Git version control" -Metaphor "Preparing your Memory" -Why "Git tracks every change. Never lose work, always able to go back."

if (Get-Command git -ErrorAction SilentlyContinue) {
    $v = (git --version) -replace "git version ", ""
    Write-AlreadyInstalled -Message "Memory initialized" -Version "Git $v"
    $results.Installed += "Git"
} else {
    try {
        winget install Git.Git --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Success -Message "Memory initialized" -Detail "Git"
            $results.Installed += "Git"
        } else {
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Write-Success -Message "Memory initialized" -Detail "Git"
            $results.Installed += "Git"
        }
    } catch {
        Write-Problem "Git installation needs attention — visit git-scm.com"
        $results.Failed += "Git"
    }
}

# ───────────────────────────────────────────────────────────────────────────────
# 2. Node.js — The Heartbeat
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing Node.js runtime" -Metaphor "Igniting the Heartbeat" -Why "The engine that powers Claude Code and modern development tools."

if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (node --version)
    Write-AlreadyInstalled -Message "Heartbeat strong" -Version "Node.js $v"
    $results.Installed += "Node.js"
} else {
    try {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Success -Message "Heartbeat strong" -Detail "Node.js"
        $results.Installed += "Node.js"
    } catch {
        Write-Problem "Node.js installation needs attention"
        $results.Failed += "Node.js"
    }
}

# ───────────────────────────────────────────────────────────────────────────────
# 3. Python — The Serpent (Optional)
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing Python" -Metaphor "Summoning ancient wisdom" -Why "A versatile language for data science, automation, and countless workflows."

if (Get-Command python -ErrorAction SilentlyContinue) {
    $v = (python --version)
    Write-AlreadyInstalled -Message "Wisdom acquired" -Version "$v"
    $results.Installed += "Python"
} else {
    try {
        winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Success -Message "Wisdom acquired" -Detail "Python"
        $results.Installed += "Python"
    } catch {
        Write-Skipped "Python not found — that's okay, it's optional"
        $results.Skipped += "Python"
    }
}

# ───────────────────────────────────────────────────────────────────────────────
# 4. Claude Code CLI — The Voice
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing Claude Code CLI" -Metaphor "Awakening the Voice" -Why "The heart of the experience. Your AI coding companion in the terminal."

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-AlreadyInstalled -Message "The Voice is ready" -Version "Claude Code CLI"
    $results.Installed += "Claude Code CLI"
} else {
    try {
        Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1")
        $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
        Write-Success -Message "The Voice is ready" -Detail "Claude Code CLI"
        $results.Installed += "Claude Code CLI"
    } catch {
        Write-Problem "Claude Code installation needs attention"
        $results.Failed += "Claude Code CLI"
    }
}

# ───────────────────────────────────────────────────────────────────────────────
# 5. VS Code — The Canvas
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Setting up VS Code" -Metaphor "Opening your Canvas" -Why "A powerful editor where you'll write and organize your projects."

$vscodeInstalled = Get-Command code -ErrorAction SilentlyContinue

if ($vscodeInstalled) {
    Write-AlreadyInstalled -Message "Canvas already open" -Version "VS Code"
    $results.Installed += "VS Code"
} else {
    try {
        winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent 2>$null | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Success -Message "Canvas prepared" -Detail "VS Code"
        $results.Installed += "VS Code"
        $vscodeInstalled = $true
    } catch {
        Write-Problem "VS Code installation needs attention"
        $results.Failed += "VS Code"
    }
}

# ───────────────────────────────────────────────────────────────────────────────
# 6. Claude Extension — The Bridge
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Connecting Claude to your editor" -Metaphor "Building the Bridge" -Why "Chat with Claude directly in VS Code. Context carried into your workspace."

if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensions = code --list-extensions 2>$null

    if ($extensions -contains "anthropic.claude-code") {
        Write-AlreadyInstalled -Message "Bridge connected" -Version "Claude Extension"
        $results.Installed += "Claude Extension"
    } else {
        try {
            code --install-extension anthropic.claude-code --force 2>$null | Out-Null
            Write-Success -Message "Bridge connected" -Detail "Claude Extension"
            $results.Installed += "Claude Extension"
        } catch {
            Write-Problem "Claude extension needs manual install from VS Code marketplace"
            $results.Failed += "Claude Extension"
        }
    }
} else {
    Write-Skipped "VS Code not available — skipping extension"
    $results.Skipped += "Claude Extension"
}

# ───────────────────────────────────────────────────────────────────────────────
# 7. Foam — The Knowledge Web
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing Foam for VS Code" -Metaphor "Weaving your Knowledge Web" -Why "A note-taking system that links your thoughts. Great for documenting and learning."

if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensions = code --list-extensions 2>$null

    if ($extensions -contains "foam.foam-vscode") {
        Write-AlreadyInstalled -Message "Web woven" -Version "Foam"
        $results.Installed += "Foam"
    } else {
        try {
            code --install-extension foam.foam-vscode --force 2>$null | Out-Null
            Write-Success -Message "Web woven" -Detail "Foam"
            $results.Installed += "Foam"
        } catch {
            Write-Skipped "Foam is optional — install later from VS Code marketplace"
            $results.Skipped += "Foam"
        }
    }
} else {
    Write-Skipped "VS Code not available — skipping Foam"
    $results.Skipped += "Foam"
}

# ───────────────────────────────────────────────────────────────────────────────
# 8. Starter Skills — The Scrolls
# ───────────────────────────────────────────────────────────────────────────────

Write-Installing -Name "Installing starter skills" -Metaphor "Unrolling the Scrolls" -Why "Pre-built commands like /help and /getting-started for instant guidance."

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

Welcome to Claude Code! This skill helps you understand what's possible.

## What Claude Code Can Do

**Write & Edit Code**
Ask Claude to write functions, fix bugs, or refactor code in any language.

**Navigate Your Codebase**
Claude can read files, search for patterns, and understand project structure.

**Run Commands**
Execute terminal commands, run tests, and manage your development workflow.

**Learn & Explain**
Get explanations of code, concepts, or errors in plain language.

## Tips for Great Results

1. **Be specific** — "Add error handling to the login function" works better than "fix the code"
2. **Share context** — Mention the file, function, or error message
3. **Iterate** — Claude learns from your feedback in the conversation

## Try These First

- "Explain what this project does"
- "Find all TODO comments in the codebase"
- "Help me write tests for [function name]"
- "What would you improve about this code?"
"@ | Set-Content "$skillsDir\SKILL.md" -Encoding UTF8

    @"
# Help

Welcome to Claude Code Framework!

## Quick Start
Type `/getting-started` for a guided tour of what Claude Code can do.

## Common Commands
- `/help` — Show this help
- `/getting-started` — Interactive tutorial
- `claude` — Start a conversation with Claude

## What Claude Code Can Do
- Write and explain code in any language
- Create, edit, and organize files
- Run terminal commands
- Debug errors and suggest fixes
- Answer questions about your codebase

## Learn More
Visit: https://github.com/anthropics/claude-code
"@ | Set-Content "$commandsDir\help.md" -Encoding UTF8

    Write-Success -Message "Scrolls ready" -Detail "Starter Skills"
    $results.Installed += "Starter Skills"
} catch {
    Write-Problem "Starter skills need manual setup"
    $results.Failed += "Starter Skills"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Completion
# ═══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "$($C.Sage)$($C.Bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($C.Reset)"
Write-Host ""
Write-Host "$($C.Cream)$($C.Bold)   Your toolkit is ready.$($C.Reset)"
Write-Host ""
Write-Host "$($C.Sage)$($C.Bold)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($C.Reset)"
Write-Host ""

# Summary
Write-Host "$($C.Sand)Everything is installed and configured.$($C.Reset)"
Write-Host ""

foreach ($item in $results.Installed) {
    Write-Host "$($C.Sage)$Check$($C.Reset) $item"
}
foreach ($item in $results.Skipped) {
    Write-Host "$($C.Dim)$Dot $item (optional, skipped)$($C.Reset)"
}
foreach ($item in $results.Failed) {
    Write-Host "$($C.Coral)$Dot$($C.Reset) $item $($C.Dim)— needs attention$($C.Reset)"
}

Write-Host ""
Write-Host "$($C.Cream)What's next:$($C.Reset)"
Write-Host ""
Write-Host "  $($C.Gold)1.$($C.Reset) $($C.Sand)Open a new terminal window$($C.Reset)"
Write-Host "  $($C.Gold)2.$($C.Reset) $($C.Sand)Type $($C.Cream)claude$($C.Reset) $($C.Sand)to start a conversation$($C.Reset)"
Write-Host "  $($C.Gold)3.$($C.Reset) $($C.Sand)Try $($C.Cream)/help$($C.Reset) $($C.Sand)to see available commands$($C.Reset)"
Write-Host ""
Write-Host "$($C.Dim)───────────────────────────────────────────$($C.Reset)"
Write-Host ""
Write-Host "$($C.Sand)First thing to try:$($C.Reset)"
Write-Host ""
Write-Host "  $($C.Cream)claude `"Help me create my first project`"$($C.Reset)"
Write-Host ""
Write-Host "$($C.Dim)───────────────────────────────────────────$($C.Reset)"
Write-Host ""
Write-Host "$($C.Gold)$Sparkle$($C.Reset) $($C.Sand)What will you create?$($C.Reset)"
Write-Host ""

# Optionally launch Claude Code
$launch = Read-Host "  Press ENTER to open Claude Code (or type 'skip' to exit)"
if ($launch -ne "skip") {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "$($C.Sand)Opening Claude Code...$($C.Reset)"
        Start-Process "claude"
    }
}

Write-Host ""
