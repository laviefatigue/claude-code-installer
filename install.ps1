# Claude Code Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# Known paths
# ============================================================================
$tempDir = Join-Path $env:TEMP "claude-setup"
$nodePath = "$env:ProgramFiles\nodejs"
$npmExe = "$nodePath\npm.cmd"
$nodeExe = "$nodePath\node.exe"
$gitExe = "$env:ProgramFiles\Git\cmd\git.exe"
$codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
$claudeExe = "$env:APPDATA\npm\claude.cmd"

# ============================================================================
# Helpers
# ============================================================================

function Get-CodePath {
    if (Test-Path $codeExe) { return $codeExe }
    if (Test-Path $codeExeAlt) { return $codeExeAlt }
    return $null
}

function Test-Installed {
    param([string]$Name)
    switch ($Name) {
        "node" { return (Test-Path $nodeExe) -or (Get-Command node -EA SilentlyContinue) }
        "git" { return (Test-Path $gitExe) -or (Get-Command git -EA SilentlyContinue) }
        "code" { return (Get-CodePath) -ne $null }
        "claude" { return (Test-Path $claudeExe) -or (Get-Command claude -EA SilentlyContinue) }
    }
    return $false
}

function Show-Progress {
    param([string]$Activity, [int]$Percent)

    $width = 30
    $complete = [math]::Floor($width * $Percent / 100)
    $remaining = $width - $complete

    $bar = ("█" * $complete) + ("░" * $remaining)

    Write-Host "`r      $bar $Percent%" -NoNewline -ForegroundColor DarkCyan

    if ($Percent -eq 100) {
        Write-Host ""
    }
}

function Download-WithProgress {
    param([string]$Url, [string]$OutFile, [string]$Name)

    try {
        $webClient = New-Object System.Net.WebClient

        $downloadComplete = $false

        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $EventArgs.ProgressPercentage
            Show-Progress -Activity "Downloading" -Percent $percent
        } | Out-Null

        Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -Action {
            $downloadComplete = $true
        } | Out-Null

        $webClient.DownloadFileAsync([Uri]$Url, $OutFile)

        while (-not $downloadComplete) {
            Start-Sleep -Milliseconds 100
        }

        # Clean up events
        Get-EventSubscriber | Unregister-Event -Force

        return $true
    } catch {
        # Fallback to simple download
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        return $true
    }
}

# ============================================================================
# Welcome
# ============================================================================

Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║                                                           ║" -ForegroundColor DarkCyan
Write-Host "  ║           " -NoNewline -ForegroundColor DarkCyan
Write-Host "Welcome to Claude Code" -NoNewline -ForegroundColor White
Write-Host "                        ║" -ForegroundColor DarkCyan
Write-Host "  ║                                                           ║" -ForegroundColor DarkCyan
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  This installer will set up everything you need to start" -ForegroundColor Gray
Write-Host "  creating with Claude in VS Code." -ForegroundColor Gray
Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What we'll install:" -ForegroundColor White
Write-Host ""
Write-Host "    1. Node.js    " -NoNewline -ForegroundColor Cyan
Write-Host "Lets your computer run Claude" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    2. Git        " -NoNewline -ForegroundColor Cyan
Write-Host "Saves your work automatically" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    3. VS Code    " -NoNewline -ForegroundColor Cyan
Write-Host "Where you and Claude work together" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    4. Claude     " -NoNewline -ForegroundColor Cyan
Write-Host "Your AI partner for building things" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  This takes about 5 minutes. You can cancel anytime with Ctrl+C." -ForegroundColor DarkGray
Write-Host ""

$response = Read-Host "  Ready to begin? [Y/n]"

if ($response -eq "n" -or $response -eq "N") {
    Write-Host ""
    Write-Host "  No problem! Run this command again when you're ready." -ForegroundColor Gray
    Write-Host ""
    exit
}

# Setup temp directory
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# ============================================================================
# 1. Node.js
# ============================================================================

Write-Host "  [1/4] " -NoNewline -ForegroundColor Yellow
Write-Host "Node.js" -ForegroundColor White
Write-Host "        Claude speaks JavaScript. Node.js lets your" -ForegroundColor DarkGray
Write-Host "        computer understand what Claude is saying." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "node") {
    $version = & node --version 2>$null
    Write-Host "      ✓ Already installed " -NoNewline -ForegroundColor Green
    Write-Host "$version" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray

    $installer = Join-Path $tempDir "node.msi"
    $url = "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi"

    # Simple progress simulation for download
    for ($i = 0; $i -le 100; $i += 5) {
        Show-Progress -Percent $i

        if ($i -eq 0) {
            # Start actual download
            $job = Start-Job -ScriptBlock {
                param($u, $o)
                Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing
            } -ArgumentList $url, $installer
        }

        if ($i -lt 100) {
            Start-Sleep -Milliseconds 200
        }
    }

    # Wait for download to complete
    Wait-Job $job | Out-Null
    Remove-Job $job

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait

    if (Test-Path $nodeExe) {
        Write-Host "      ✓ Installed" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Installation may need a restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 2. Git
# ============================================================================

Write-Host "  [2/4] " -NoNewline -ForegroundColor Yellow
Write-Host "Git" -ForegroundColor White
Write-Host "        Like a save game for your work. Every change" -ForegroundColor DarkGray
Write-Host "        is saved, so you can always go back if needed." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "git") {
    $version = & git --version 2>$null
    $version = $version -replace "git version ", ""
    Write-Host "      ✓ Already installed " -NoNewline -ForegroundColor Green
    Write-Host "v$version" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray

    $installer = Join-Path $tempDir "git.exe"
    $url = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe"

    for ($i = 0; $i -le 100; $i += 4) {
        Show-Progress -Percent $i

        if ($i -eq 0) {
            $job = Start-Job -ScriptBlock {
                param($u, $o)
                Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing
            } -ArgumentList $url, $installer
        }

        if ($i -lt 100) {
            Start-Sleep -Milliseconds 250
        }
    }

    Wait-Job $job | Out-Null
    Remove-Job $job

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait

    if (Test-Path $gitExe) {
        Write-Host "      ✓ Installed" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Installation may need a restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 3. VS Code
# ============================================================================

Write-Host "  [3/4] " -NoNewline -ForegroundColor Yellow
Write-Host "VS Code" -ForegroundColor White
Write-Host "        Your workspace. Like Google Docs, but for code." -ForegroundColor DarkGray
Write-Host "        This is where you and Claude work together." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "code") {
    Write-Host "      ✓ Already installed" -ForegroundColor Green
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray

    $installer = Join-Path $tempDir "vscode.exe"
    $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

    for ($i = 0; $i -le 100; $i += 3) {
        Show-Progress -Percent $i

        if ($i -eq 0) {
            $job = Start-Job -ScriptBlock {
                param($u, $o)
                Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing
            } -ArgumentList $url, $installer
        }

        if ($i -lt 100) {
            Start-Sleep -Milliseconds 300
        }
    }

    Wait-Job $job | Out-Null
    Remove-Job $job

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait
    Start-Sleep -Seconds 2

    if (Get-CodePath) {
        Write-Host "      ✓ Installed" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Installation may need a restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 4. Claude Code
# ============================================================================

Write-Host "  [4/4] " -NoNewline -ForegroundColor Yellow
Write-Host "Claude Code" -ForegroundColor White
Write-Host "        Your AI partner. Describe what you want to" -ForegroundColor DarkGray
Write-Host "        build, and Claude helps you create it." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "claude") {
    Write-Host "      ✓ Already installed" -ForegroundColor Green
} else {
    Write-Host "      Installing..." -ForegroundColor Gray

    # Update PATH for this session
    $env:Path = "$nodePath;$env:APPDATA\npm;$env:Path"

    if (Test-Path $npmExe) {
        & $npmExe install -g @anthropic-ai/claude-code 2>$null | Out-Null

        if (Test-Installed "claude") {
            Write-Host "      ✓ Installed" -ForegroundColor Green
        } else {
            Write-Host "      ! Will complete after restart" -ForegroundColor Yellow
        }
    } else {
        # npm not ready - spawn new PowerShell to install
        $script = "`$env:Path = `"$nodePath;$env:APPDATA\npm;`$env:Path`"; npm install -g @anthropic-ai/claude-code"
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command $script" -Wait -WindowStyle Hidden

        if (Test-Path $claudeExe) {
            Write-Host "      ✓ Installed" -ForegroundColor Green
        } else {
            Write-Host "      ! Run after restart: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# ============================================================================
# Extension
# ============================================================================

Write-Host "  [+] " -NoNewline -ForegroundColor DarkCyan
Write-Host "Claude Extension for VS Code" -ForegroundColor Gray

$codePath = Get-CodePath
if ($codePath) {
    & $codePath --install-extension anthropic.claude-code --force 2>$null | Out-Null
    Write-Host "      ✓ Added" -ForegroundColor Green
} else {
    Write-Host "      - Will install when VS Code opens" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================================
# Complete
# ============================================================================

Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                                           ║" -ForegroundColor Green
Write-Host "  ║              " -NoNewline -ForegroundColor Green
Write-Host "Setup Complete!" -NoNewline -ForegroundColor White
Write-Host "                            ║" -ForegroundColor Green
Write-Host "  ║                                                           ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  What's next:" -ForegroundColor White
Write-Host ""
Write-Host "    1. VS Code will open" -ForegroundColor Gray
Write-Host "    2. A visual guide will show you where everything is" -ForegroundColor Gray
Write-Host "    3. Sign in to Claude and start creating" -ForegroundColor Gray
Write-Host ""

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

$null = Read-Host "  Press ENTER to open VS Code"

# Open VS Code
$codePath = Get-CodePath
if ($codePath) {
    Start-Process $codePath
} else {
    Start-Process "code" -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 1

# Open tutorial
Start-Process "https://laviefatigue.github.io/claude-code-installer/onboarding.html"

Write-Host ""
Write-Host "  ✓ VS Code is opening..." -ForegroundColor Green
Write-Host "  ✓ Tutorial opened in your browser" -ForegroundColor Green
Write-Host ""
Write-Host "  Enjoy creating with Claude!" -ForegroundColor Cyan
Write-Host ""
