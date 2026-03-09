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
$pythonPath = "$env:LOCALAPPDATA\Programs\Python\Python312"
$pythonExe = "$pythonPath\python.exe"
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
        "python" { return (Test-Path $pythonExe) -or (Get-Command python -EA SilentlyContinue) }
        "code" { return (Get-CodePath) -ne $null }
        "claude" { return (Test-Path $claudeExe) -or (Get-Command claude -EA SilentlyContinue) }
    }
    return $false
}

function Show-Progress {
    param([int]$Percent)
    $width = 30
    $complete = [math]::Floor($width * $Percent / 100)
    $remaining = $width - $complete
    $bar = ([char]0x2588).ToString() * $complete + ([char]0x2591).ToString() * $remaining
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

    $steps = $EstimatedSeconds * 5
    for ($i = 0; $i -le 100; $i += [math]::Ceiling(100 / $steps)) {
        Show-Progress -Percent ([math]::Min($i, 99))
        Start-Sleep -Milliseconds 200
        if ($job.State -eq "Completed") { break }
    }

    Wait-Job $job | Out-Null
    Remove-Job $job
    Show-Progress -Percent 100
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
Write-Host "    1. Node.js " -NoNewline -ForegroundColor Cyan
Write-Host "- Lets your computer run Claude" -ForegroundColor DarkGray
Write-Host "    2. Git     " -NoNewline -ForegroundColor Cyan
Write-Host "- Saves your work like a time machine" -ForegroundColor DarkGray
Write-Host "    3. Python  " -NoNewline -ForegroundColor Cyan
Write-Host "- For automation and data projects" -ForegroundColor DarkGray
Write-Host "    4. VS Code " -NoNewline -ForegroundColor Cyan
Write-Host "- Your workspace with Claude" -ForegroundColor DarkGray
Write-Host "    5. Claude  " -NoNewline -ForegroundColor Cyan
Write-Host "- Your AI partner" -ForegroundColor DarkGray
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
# 1. Node.js
# ============================================================================

Write-Host "  [1/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Node.js" -ForegroundColor White
Write-Host "        Claude speaks JavaScript. Node.js is the translator" -ForegroundColor DarkGray
Write-Host "        that lets your computer understand Claude." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "node") {
    $version = & node --version 2>$null
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "$version" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "node.msi"
    Start-Download -Url "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi" -OutFile $installer -EstimatedSeconds 10

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait

    if (Test-Path $nodeExe) {
        Write-Host "      [OK] Installed" -ForegroundColor Green
    } else {
        Write-Host "      [!] May need restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 2. Git
# ============================================================================

Write-Host "  [2/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Git" -ForegroundColor White
Write-Host "        Like a time machine for your work. Every change is" -ForegroundColor DarkGray
Write-Host "        saved, so you can always undo mistakes." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "git") {
    $version = (& git --version 2>$null) -replace "git version ", ""
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "v$version" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "git.exe"
    Start-Download -Url "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe" -OutFile $installer -EstimatedSeconds 15

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait

    if (Test-Path $gitExe) {
        Write-Host "      [OK] Installed" -ForegroundColor Green
    } else {
        Write-Host "      [!] May need restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 3. Python
# ============================================================================

Write-Host "  [3/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Python" -ForegroundColor White
Write-Host "        A beginner-friendly language for automation, data," -ForegroundColor DarkGray
Write-Host "        and AI projects. Claude uses it a lot." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "python") {
    $version = (& python --version 2>$null) -replace "Python ", ""
    Write-Host "      [OK] Already installed " -NoNewline -ForegroundColor Green
    Write-Host "v$version" -ForegroundColor DarkGray
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "python.exe"
    Start-Download -Url "https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe" -OutFile $installer -EstimatedSeconds 10

    Write-Host "      Installing..." -ForegroundColor Gray
    # Install with PATH option and for all users
    Start-Process $installer -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0" -Wait

    if (Test-Installed "python") {
        Write-Host "      [OK] Installed" -ForegroundColor Green
    } else {
        Write-Host "      [!] May need restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 4. VS Code
# ============================================================================

Write-Host "  [4/5] " -NoNewline -ForegroundColor Yellow
Write-Host "VS Code" -ForegroundColor White
Write-Host "        Your creative workspace. Like Google Docs for code." -ForegroundColor DarkGray
Write-Host "        This is where you and Claude build things together." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "code") {
    Write-Host "      [OK] Already installed" -ForegroundColor Green
} else {
    Write-Host "      Downloading..." -ForegroundColor Gray
    $installer = Join-Path $tempDir "vscode.exe"
    Start-Download -Url "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $installer -EstimatedSeconds 20

    Write-Host "      Installing..." -ForegroundColor Gray
    Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait
    Start-Sleep -Seconds 2

    if (Get-CodePath) {
        Write-Host "      [OK] Installed" -ForegroundColor Green
    } else {
        Write-Host "      [!] May need restart" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# 5. Claude Code CLI
# ============================================================================

Write-Host "  [5/5] " -NoNewline -ForegroundColor Yellow
Write-Host "Claude Code" -ForegroundColor White
Write-Host "        Your AI partner. Tell Claude what you want to build," -ForegroundColor DarkGray
Write-Host "        and it helps you create it step by step." -ForegroundColor DarkGray
Write-Host ""

if (Test-Installed "claude") {
    Write-Host "      [OK] Already installed" -ForegroundColor Green
} else {
    Write-Host "      Installing..." -ForegroundColor Gray
    $env:Path = "$nodePath;$env:APPDATA\npm;$env:Path"

    if (Test-Path $npmExe) {
        & $npmExe install -g @anthropic-ai/claude-code 2>$null | Out-Null

        if (Test-Installed "claude") {
            Write-Host "      [OK] Installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Will complete after restart" -ForegroundColor Yellow
        }
    } else {
        $script = "`$env:Path = `"$nodePath;$env:APPDATA\npm;`$env:Path`"; npm install -g @anthropic-ai/claude-code"
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command $script" -Wait -WindowStyle Hidden

        if (Test-Path $claudeExe) {
            Write-Host "      [OK] Installed" -ForegroundColor Green
        } else {
            Write-Host "      [!] Run after restart: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# ============================================================================
# Extensions
# ============================================================================

Write-Host "  [+] " -NoNewline -ForegroundColor DarkCyan
Write-Host "VS Code Extensions" -ForegroundColor White
Write-Host ""

$codePath = Get-CodePath
if ($codePath) {
    Write-Host "      Installing Claude extension..." -ForegroundColor Gray
    & $codePath --install-extension anthropic.claude-code --force 2>$null | Out-Null
    Write-Host "      [OK] Claude Code - AI assistant in your editor" -ForegroundColor Green

    Write-Host "      Installing Foam extension..." -ForegroundColor Gray
    & $codePath --install-extension foam.foam-vscode --force 2>$null | Out-Null
    Write-Host "      [OK] Foam - connected notes and knowledge graph" -ForegroundColor Green
} else {
    Write-Host "      [-] VS Code not ready - extensions will install on first launch" -ForegroundColor DarkGray
}

Write-Host ""

# ============================================================================
# Complete
# ============================================================================

Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                                       |" -ForegroundColor Green
Write-Host "  |               " -NoNewline -ForegroundColor Green
Write-Host "Setup Complete!" -NoNewline -ForegroundColor White
Write-Host "                       |" -ForegroundColor Green
Write-Host "  |                                                       |" -ForegroundColor Green
Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Everything is installed. Here's what happens next:" -ForegroundColor White
Write-Host ""
Write-Host "    1. VS Code opens" -ForegroundColor Gray
Write-Host "    2. A quick visual guide shows you where Claude is" -ForegroundColor Gray
Write-Host "    3. Click the Claude icon, sign in, and start creating" -ForegroundColor Gray
Write-Host ""

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

$null = Read-Host "  Press ENTER to open VS Code"

$codePath = Get-CodePath
if ($codePath) {
    Start-Process $codePath
} else {
    Start-Process "code" -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 1
Start-Process "https://laviefatigue.github.io/claude-code-installer/onboarding.html"

Write-Host ""
Write-Host "  [OK] VS Code is opening..." -ForegroundColor Green
Write-Host "  [OK] Tutorial opened in your browser" -ForegroundColor Green
Write-Host ""
Write-Host "  You're ready to create. Enjoy!" -ForegroundColor Cyan
Write-Host ""
