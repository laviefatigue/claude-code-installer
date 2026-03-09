# Claude Code Framework Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# Output Helpers
# ============================================================================

function Write-Logo {
    Clear-Host
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
    param([string]$Number, [string]$Title, [string]$Description)
    Write-Host ""
    Write-Host "  [$Number] " -NoNewline -ForegroundColor DarkYellow
    Write-Host "$Title" -ForegroundColor White
    Write-Host "        $Description" -ForegroundColor DarkGray
}

function Write-Status {
    param([string]$Message)
    Write-Host "        $Message" -ForegroundColor Gray
}

function Write-OK {
    param([string]$Message)
    Write-Host "        [OK] " -NoNewline -ForegroundColor Green
    Write-Host "$Message" -ForegroundColor White
}

function Write-Already {
    param([string]$Message, [string]$Version)
    Write-Host "        [OK] " -NoNewline -ForegroundColor Green
    Write-Host "$Message " -NoNewline -ForegroundColor White
    Write-Host "$Version" -ForegroundColor DarkGray
}

function Write-Fail {
    param([string]$Message)
    Write-Host "        [X]  " -NoNewline -ForegroundColor Red
    Write-Host "$Message" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Message)
    Write-Host "        [--] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$Message" -ForegroundColor DarkGray
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ============================================================================
# Installation Functions
# ============================================================================

function Install-NodeJS {
    Write-Step "1/5" "Node.js" "The engine that powers Claude Code"

    # Check if already installed
    Refresh-Path
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        $v = & node --version 2>$null
        Write-Already "Node.js already installed" "$v"
        return $true
    }

    Write-Status "Downloading Node.js installer..."

    $tempDir = Join-Path $env:TEMP "claude-installer"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Download Node.js LTS
    $nodeUrl = "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
    $nodeInstaller = Join-Path $tempDir "nodejs.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
    } catch {
        Write-Fail "Download failed - check your internet connection"
        return $false
    }

    Write-Status "Installing Node.js (follow the wizard)..."

    # Run installer and wait
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeInstaller`" /passive" -Wait -PassThru

    # Refresh PATH
    Refresh-Path

    # Verify
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        $v = & node --version 2>$null
        Write-OK "Node.js installed $v"
        return $true
    } else {
        Write-Fail "Node.js installation incomplete - please restart PowerShell after setup"
        return $false
    }
}

function Install-Git {
    Write-Step "2/5" "Git" "Tracks every change you make. Never lose work."

    # Check if already installed
    Refresh-Path
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $v = & git --version 2>$null
        $v = $v -replace "git version ", ""
        Write-Already "Git already installed" "v$v"
        return $true
    }

    Write-Status "Downloading Git installer..."

    $tempDir = Join-Path $env:TEMP "claude-installer"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Download Git for Windows
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
    $gitInstaller = Join-Path $tempDir "git-installer.exe"

    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
    } catch {
        Write-Fail "Download failed - check your internet connection"
        return $false
    }

    Write-Status "Installing Git (follow the wizard)..."

    # Run installer with sensible defaults, wait for completion
    $process = Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -Wait -PassThru

    # Refresh PATH
    Refresh-Path

    # Also add common Git paths manually
    $gitPaths = @(
        "$env:ProgramFiles\Git\cmd",
        "$env:ProgramFiles\Git\bin",
        "${env:ProgramFiles(x86)}\Git\cmd"
    )
    foreach ($p in $gitPaths) {
        if (Test-Path $p) {
            $env:Path = "$p;$env:Path"
        }
    }

    # Verify
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $v = & git --version 2>$null
        Write-OK "Git installed"
        return $true
    } else {
        Write-Fail "Git installation incomplete - you may need to restart PowerShell"
        return $false
    }
}

function Install-ClaudeCode {
    Write-Step "3/5" "Claude Code CLI" "Your AI coding companion"

    # Check if already installed
    Refresh-Path
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if ($claude) {
        Write-Already "Claude Code already installed" ""
        return $true
    }

    # Check if npm is available
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Fail "Node.js/npm not found - Claude Code requires Node.js"
        return $false
    }

    Write-Status "Installing Claude Code via npm..."

    try {
        # Install globally
        & npm install -g @anthropic-ai/claude-code 2>$null | Out-Null

        # Add npm global bin to path
        $npmPrefix = & npm config get prefix 2>$null
        if ($npmPrefix) {
            $env:Path = "$npmPrefix;$env:Path"
        }

        # Also check common locations
        $localBin = "$env:USERPROFILE\.local\bin"
        if (Test-Path $localBin) {
            $env:Path = "$localBin;$env:Path"
        }

        Refresh-Path

        # Verify
        $claude = Get-Command claude -ErrorAction SilentlyContinue
        if ($claude) {
            Write-OK "Claude Code installed"
            return $true
        } else {
            # Try the official installer as backup
            Write-Status "Trying official installer..."
            Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1") 2>$null
            $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"

            $claude = Get-Command claude -ErrorAction SilentlyContinue
            if ($claude) {
                Write-OK "Claude Code installed"
                return $true
            }

            Write-Fail "Installation incomplete - try: npm install -g @anthropic-ai/claude-code"
            return $false
        }
    } catch {
        Write-Fail "Installation failed"
        return $false
    }
}

function Install-VSCode {
    Write-Step "4/5" "VS Code" "A powerful editor where you'll build and create"

    # Check if already installed
    Refresh-Path
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) {
        Write-Already "VS Code already installed" ""
        return $true
    }

    Write-Status "Downloading VS Code installer..."

    $tempDir = Join-Path $env:TEMP "claude-installer"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Download VS Code
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
    $vscodeInstaller = Join-Path $tempDir "vscode-installer.exe"

    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeInstaller -UseBasicParsing
    } catch {
        Write-Fail "Download failed - check your internet connection"
        return $false
    }

    Write-Status "Installing VS Code (follow the wizard)..."

    # Run installer - use /SILENT for automatic, but show progress
    $process = Start-Process -FilePath $vscodeInstaller -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait -PassThru

    # Refresh PATH
    Refresh-Path

    # Add common VS Code paths
    $vscodePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "$env:ProgramFiles\Microsoft VS Code\bin"
    )
    foreach ($p in $vscodePaths) {
        if (Test-Path $p) {
            $env:Path = "$p;$env:Path"
        }
    }

    # Verify
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) {
        Write-OK "VS Code installed"
        return $true
    } else {
        Write-Fail "VS Code installation incomplete - you may need to restart PowerShell"
        return $false
    }
}

function Install-Extensions {
    Write-Step "5/5" "VS Code Extensions" "Claude extension + useful tools"

    Refresh-Path
    $code = Get-Command code -ErrorAction SilentlyContinue
    if (-not $code) {
        Write-Skip "VS Code not available - skipping extensions"
        return $false
    }

    Write-Status "Installing Claude extension..."

    try {
        & code --install-extension anthropic.claude-code --force 2>$null | Out-Null
        Write-OK "Claude extension installed"
    } catch {
        Write-Fail "Claude extension failed - install from VS Code marketplace"
    }

    Write-Status "Installing Foam extension (connected notes)..."

    try {
        & code --install-extension foam.foam-vscode --force 2>$null | Out-Null
        Write-OK "Foam extension installed"
    } catch {
        Write-Skip "Foam skipped - optional"
    }

    return $true
}

# ============================================================================
# Main
# ============================================================================

Write-Logo

Write-Host "  We're about to set up your creative toolkit." -ForegroundColor Gray
Write-Host "  This takes about 5 minutes." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What we'll install:" -ForegroundColor White
Write-Host ""
Write-Host "    1. Node.js        " -NoNewline -ForegroundColor Cyan
Write-Host "- Powers Claude Code" -ForegroundColor DarkGray
Write-Host "    2. Git            " -NoNewline -ForegroundColor Cyan
Write-Host "- Version control" -ForegroundColor DarkGray
Write-Host "    3. Claude Code    " -NoNewline -ForegroundColor Cyan
Write-Host "- Your AI companion" -ForegroundColor DarkGray
Write-Host "    4. VS Code        " -NoNewline -ForegroundColor Cyan
Write-Host "- Your editor" -ForegroundColor DarkGray
Write-Host "    5. Extensions     " -NoNewline -ForegroundColor Cyan
Write-Host "- Claude + Foam" -ForegroundColor DarkGray
Write-Host ""

$null = Read-Host "  Press ENTER to begin"

# Track results
$results = @{
    Node = $false
    Git = $false
    Claude = $false
    VSCode = $false
    Extensions = $false
}

# Install in order
$results.Node = Install-NodeJS
$results.Git = Install-Git
$results.Claude = Install-ClaudeCode
$results.VSCode = Install-VSCode
$results.Extensions = Install-Extensions

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "  =============================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "     Installation Complete" -ForegroundColor White
Write-Host ""
Write-Host "  =============================================" -ForegroundColor DarkCyan
Write-Host ""

# Show results
if ($results.Node) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "Node.js" -ForegroundColor White
} else {
    Write-Host "  [X]  " -NoNewline -ForegroundColor Red
    Write-Host "Node.js - visit nodejs.org" -ForegroundColor Yellow
}

if ($results.Git) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "Git" -ForegroundColor White
} else {
    Write-Host "  [X]  " -NoNewline -ForegroundColor Red
    Write-Host "Git - visit git-scm.com" -ForegroundColor Yellow
}

if ($results.Claude) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "Claude Code" -ForegroundColor White
} else {
    Write-Host "  [X]  " -NoNewline -ForegroundColor Red
    Write-Host "Claude Code - run: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
}

if ($results.VSCode) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "VS Code" -ForegroundColor White
} else {
    Write-Host "  [X]  " -NoNewline -ForegroundColor Red
    Write-Host "VS Code - visit code.visualstudio.com" -ForegroundColor Yellow
}

if ($results.Extensions) {
    Write-Host "  [OK] " -NoNewline -ForegroundColor Green
    Write-Host "Extensions" -ForegroundColor White
} else {
    Write-Host "  [--] " -NoNewline -ForegroundColor DarkGray
    Write-Host "Extensions - install later from VS Code" -ForegroundColor DarkGray
}

Write-Host ""

# Next steps
if ($results.VSCode -and $results.Claude) {
    Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  NEXT: Learn where everything is" -ForegroundColor White
    Write-Host ""
    Write-Host "  We'll open VS Code and a 2-minute visual guide." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    $launch = Read-Host "  Press ENTER to continue (or type 'skip')"

    if ($launch -ne "skip") {
        # Open VS Code
        Write-Host ""
        Write-Host "  Opening VS Code..." -ForegroundColor Gray
        Start-Process "code" -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 2

        # Open tutorial
        Write-Host "  Opening visual guide..." -ForegroundColor Gray
        Start-Process "https://laviefatigue.github.io/claude-code-installer/onboarding.html"
    }
} else {
    Write-Host "  Some components need attention before continuing." -ForegroundColor Yellow
    Write-Host "  Fix the issues above, then run this installer again." -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "  What will you create?" -ForegroundColor DarkYellow
Write-Host ""
