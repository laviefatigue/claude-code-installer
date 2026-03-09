# Claude Code Framework Installer
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# Setup
# ============================================================================

$tempDir = Join-Path $env:TEMP "claude-setup"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Known install locations (don't rely on PATH)
$nodePath = "$env:ProgramFiles\nodejs"
$npmExe = "$env:ProgramFiles\nodejs\npm.cmd"
$gitExe = "$env:ProgramFiles\Git\cmd\git.exe"
$codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"

# ============================================================================
# Helpers
# ============================================================================

function Write-Status { param([string]$Msg); Write-Host "  $Msg" -ForegroundColor Gray }
function Write-Done { param([string]$Msg); Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg); Write-Host "  [!] $Msg" -ForegroundColor Yellow }
function Write-Step { param([int]$N, [string]$Name); Write-Host "`n  [$N/4] $Name" -ForegroundColor Cyan }

function Get-Code {
    if (Test-Path $codeExe) { return $codeExe }
    if (Test-Path $codeExeAlt) { return $codeExeAlt }
    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Get-Npm {
    if (Test-Path $npmExe) { return $npmExe }
    $cmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Test-HasNode {
    (Test-Path "$nodePath\node.exe") -or (Get-Command node -ErrorAction SilentlyContinue)
}
function Test-HasGit {
    (Test-Path $gitExe) -or (Get-Command git -ErrorAction SilentlyContinue)
}
function Test-HasCode {
    (Get-Code) -ne $null
}
function Test-HasClaude {
    (Get-Command claude -ErrorAction SilentlyContinue) -or
    (Test-Path "$env:APPDATA\npm\claude.cmd") -or
    (Test-Path "$env:USERPROFILE\.local\bin\claude.exe")
}

# ============================================================================
# Welcome
# ============================================================================

Clear-Host
Write-Host ""
Write-Host "  =============================================" -ForegroundColor DarkCyan
Write-Host "       Claude Code - Installing..." -ForegroundColor White
Write-Host "  =============================================" -ForegroundColor DarkCyan

# ============================================================================
# 1. Node.js
# ============================================================================

Write-Step 1 "Node.js"

if (Test-HasNode) {
    Write-Done "Already installed"
} else {
    Write-Status "Downloading..."
    $installer = Join-Path $tempDir "node.msi"
    try {
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi" -OutFile $installer -UseBasicParsing
        Write-Status "Installing..."
        Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait
        Write-Done "Installed"
    } catch {
        Write-Warn "Failed - visit nodejs.org"
    }
}

# ============================================================================
# 2. Git
# ============================================================================

Write-Step 2 "Git"

if (Test-HasGit) {
    Write-Done "Already installed"
} else {
    Write-Status "Downloading..."
    $installer = Join-Path $tempDir "git.exe"
    try {
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe" -OutFile $installer -UseBasicParsing
        Write-Status "Installing..."
        Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait
        Write-Done "Installed"
    } catch {
        Write-Warn "Failed - visit git-scm.com"
    }
}

# ============================================================================
# 3. VS Code
# ============================================================================

Write-Step 3 "VS Code"

if (Test-HasCode) {
    Write-Done "Already installed"
} else {
    Write-Status "Downloading..."
    $installer = Join-Path $tempDir "vscode.exe"
    try {
        Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $installer -UseBasicParsing
        Write-Status "Installing..."
        Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait
        Start-Sleep -Seconds 3
        Write-Done "Installed"
    } catch {
        Write-Warn "Failed - visit code.visualstudio.com"
    }
}

# ============================================================================
# 4. Claude Code
# ============================================================================

Write-Step 4 "Claude Code"

if (Test-HasClaude) {
    Write-Done "Already installed"
} else {
    $npm = Get-Npm
    if ($npm) {
        Write-Status "Installing via npm..."
        try {
            # Update PATH for this session
            $env:Path = "$nodePath;$env:APPDATA\npm;$env:Path"
            & $npm install -g @anthropic-ai/claude-code 2>$null | Out-Null
            Write-Done "Installed"
        } catch {
            Write-Warn "Run later: npm install -g @anthropic-ai/claude-code"
        }
    } else {
        # Node just installed, npm not available yet
        Write-Warn "Restart PowerShell, then run: npm install -g @anthropic-ai/claude-code"
    }
}

# ============================================================================
# Extensions
# ============================================================================

Write-Host ""
Write-Status "Adding VS Code extensions..."

$code = Get-Code
if ($code) {
    & $code --install-extension anthropic.claude-code --force 2>$null | Out-Null
    Write-Done "Claude extension added"
} else {
    Write-Status "VS Code not ready - install Claude extension later"
}

# ============================================================================
# Done
# ============================================================================

Write-Host ""
Write-Host "  =============================================" -ForegroundColor DarkCyan
Write-Host "       Setup Complete!" -ForegroundColor Green
Write-Host "  =============================================" -ForegroundColor DarkCyan
Write-Host ""

# Check if Claude is available
if (Test-HasClaude) {
    Write-Host "  Everything is ready!" -ForegroundColor White
    Write-Host ""
    Write-Host "  Opening VS Code and your guide..." -ForegroundColor Gray

    Start-Sleep -Seconds 2

    # Open VS Code
    $code = Get-Code
    if ($code) { Start-Process $code }

    Start-Sleep -Seconds 1

    # Open tutorial
    Start-Process "https://laviefatigue.github.io/claude-code-installer/onboarding.html"

} else {
    Write-Host "  Almost there! Node.js needs a fresh terminal." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "    1. Close this window" -ForegroundColor Gray
    Write-Host "    2. Open a NEW PowerShell" -ForegroundColor Gray
    Write-Host "    3. Run: " -NoNewline -ForegroundColor Gray
    Write-Host "npm install -g @anthropic-ai/claude-code" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Then open VS Code and you're ready!" -ForegroundColor Gray
}

Write-Host ""

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
