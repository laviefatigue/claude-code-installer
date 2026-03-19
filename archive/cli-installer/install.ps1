# Claude Code Framework Installer
# Usage: irm https://example.com/install.ps1 | iex
# Or: .\install.ps1 -Community "base"

param(
    [string]$Community = "base",
    [switch]$SkipPrerequisites,
    [switch]$SkipAuth,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Import modules
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\modules\Check-Prerequisites.ps1"
. "$ScriptDir\modules\Install-ClaudeCode.ps1"
. "$ScriptDir\modules\Deploy-CommunityPlugin.ps1"

# Colors
function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "   [!] $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "   [X] $msg" -ForegroundColor Red }

# Banner
function Show-Banner {
    $banner = @"

   _____ _                 _         _____          _
  / ____| |               | |       / ____|        | |
 | |    | | __ _ _   _  __| | ___  | |     ___   __| | ___
 | |    | |/ _` | | | |/ _` |/ _ \ | |    / _ \ / _` |/ _ \
 | |____| | (_| | |_| | (_| |  __/ | |___| (_) | (_| |  __/
  \_____|_|\__,_|\__,_|\__,_|\___|  \_____\___/ \__,_|\___|

              Framework Installer v1.0.0

"@
    Write-Host $banner -ForegroundColor Magenta
}

# Main installation flow
function Start-Installation {
    Show-Banner

    # Load community config if available
    $CommunityPath = Join-Path $ScriptDir "..\communities\$Community"
    $PluginConfig = $null
    $PluginJsonPath = Join-Path $CommunityPath ".claude-plugin\plugin.json"

    if (Test-Path $PluginJsonPath) {
        $PluginConfig = Get-Content $PluginJsonPath | ConvertFrom-Json
        if ($PluginConfig.branding.welcome_message) {
            Write-Host $PluginConfig.branding.welcome_message -ForegroundColor White
        }
    }

    Write-Host "`nThis installer will set up Claude Code with the '$Community' community configuration.`n"

    if (-not $Quiet) {
        $confirm = Read-Host "Continue? (Y/n)"
        if ($confirm -eq "n" -or $confirm -eq "N") {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 1
        }
    }

    # Step 1: Check prerequisites
    if (-not $SkipPrerequisites) {
        Write-Step "Checking prerequisites..."

        $prereqs = Test-Prerequisites
        $allInstalled = $true

        foreach ($prereq in $prereqs) {
            if ($prereq.Installed) {
                Write-Success "$($prereq.Name) v$($prereq.Version)"
            } else {
                Write-Warn "$($prereq.Name) not found"
                $allInstalled = $false
            }
        }

        if (-not $allInstalled) {
            Write-Step "Installing missing prerequisites..."

            foreach ($prereq in $prereqs | Where-Object { -not $_.Installed }) {
                Write-Host "   Installing $($prereq.Name)..." -NoNewline

                try {
                    Install-Prerequisite -Name $prereq.Name
                    Write-Host " Done" -ForegroundColor Green
                } catch {
                    Write-Host " Failed" -ForegroundColor Red
                    Write-Fail "Could not install $($prereq.Name): $_"
                    exit 2
                }
            }
        }
    }

    # Step 2: Install Claude Code
    Write-Step "Installing Claude Code CLI..."

    $claudeInstalled = Test-ClaudeCode
    if ($claudeInstalled) {
        Write-Success "Claude Code already installed"
    } else {
        try {
            Install-ClaudeCode
            Write-Success "Claude Code installed"
        } catch {
            Write-Fail "Could not install Claude Code: $_"
            exit 3
        }
    }

    # Step 3: Authentication
    if (-not $SkipAuth) {
        Write-Step "Authentication required..."
        Write-Host "`n   Claude Code requires an Anthropic account (Pro, Max, or Teams)."
        Write-Host "   Opening browser for authentication...`n"

        # Run claude to trigger auth flow
        try {
            Start-Process "claude" -ArgumentList "--version" -NoNewWindow -Wait
        } catch {
            Write-Warn "Could not start Claude Code. You may need to restart your terminal."
        }

        Write-Host "`n   After signing in, press Enter to continue..." -NoNewline
        Read-Host
    }

    # Step 4: Deploy community plugin
    Write-Step "Deploying community plugin..."

    try {
        $result = Deploy-CommunityPlugin -CommunityPath $CommunityPath
        Write-Success "Plugin deployed to $($result.PluginPath)"

        if ($result.SkillsCount -gt 0) {
            Write-Success "$($result.SkillsCount) skills installed"
        }
        if ($result.CommandsCount -gt 0) {
            Write-Success "$($result.CommandsCount) commands installed"
        }
    } catch {
        Write-Fail "Could not deploy plugin: $_"
        exit 5
    }

    # Step 5: Complete
    Write-Step "Installation complete!"

    $quickStart = @"

   Quick Start:
   ------------
   1. Open VS Code
   2. Press Ctrl+` to open terminal
   3. Type 'claude' to start
   4. Type '/help' for available commands

"@
    Write-Host $quickStart -ForegroundColor White

    if (-not $Quiet) {
        $openVSCode = Read-Host "Open VS Code now? (Y/n)"
        if ($openVSCode -ne "n" -and $openVSCode -ne "N") {
            try {
                Start-Process "code"
            } catch {
                Write-Warn "Could not open VS Code. Please open it manually."
            }
        }
    }

    Write-Host "`nEnjoy using Claude Code!" -ForegroundColor Green
    exit 0
}

# Run installation
Start-Installation
