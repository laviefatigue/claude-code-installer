# ============================================================================
# Replace University — Claude Code Installer (EXE Wrapper)
# This script is compiled into an .exe via ps2exe.
# It downloads and executes the main install.ps1 in an isolated process.
# ============================================================================

$host.UI.RawUI.WindowTitle = "Replace University — Claude Code Setup"

# Try to resize console for a clean look
try {
    $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(90, 35)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(90, 3000)
} catch {}

# Set dark background
try {
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "White"
    Clear-Host
} catch {}

# ── Branded Welcome ──

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "       ____            _                                       " -ForegroundColor White
Write-Host "      |  _ \ ___ _ __ | | __ _  ___ ___                       " -ForegroundColor White
Write-Host "      | |_) / _ \ '_ \| |/ _`` |/ __/ _ \                     " -ForegroundColor White
Write-Host "      |  _ <  __/ |_) | | (_| | (_|  __/                      " -ForegroundColor White
Write-Host "      |_| \_\___| .__/|_|\__,_|\___\___|                      " -ForegroundColor White
Write-Host "                |_|                                            " -ForegroundColor White
Write-Host "                     U N I V E R S I T Y                      " -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  The community where normal people learn to build with AI." -ForegroundColor Gray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  This installer will set up everything you need:" -ForegroundColor White
Write-Host ""
Write-Host "    Git            version control" -ForegroundColor Gray
Write-Host "    Node.js        powers Claude Code" -ForegroundColor Gray
Write-Host "    VS Code        your code editor" -ForegroundColor Gray
Write-Host "    Claude Code    your AI builder" -ForegroundColor Gray
Write-Host "    uv             fast package manager" -ForegroundColor Gray
Write-Host "    GitHub CLI     share your work" -ForegroundColor Gray
Write-Host ""
Write-Host "  No coding knowledge required." -ForegroundColor DarkGray
Write-Host "  Estimated time: 5 minutes." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor DarkGray
Write-Host ""

$response = Read-Host "  Ready to start? [Y/n]"
if ($response -eq "n" -or $response -eq "N") {
    Write-Host ""
    Write-Host "  No worries. Run this again when you're ready." -ForegroundColor Gray
    Write-Host ""
    Read-Host "  Press ENTER to close"
    return
}

Write-Host ""
Write-Host "  Starting installation..." -ForegroundColor White
Write-Host ""

# ── Download and run the installer ──

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch {}

    $installerUrl = "https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1"
    $installerScript = Invoke-RestMethod -Uri $installerUrl -UseBasicParsing

    # Run the installer inline — it uses return (not exit) so it won't close this window
    $scriptBlock = [ScriptBlock]::Create($installerScript)
    & $scriptBlock

} catch {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Something went wrong downloading the installer." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Check your internet connection and try again, or run" -ForegroundColor Gray
    Write-Host "  this command in PowerShell instead:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host ""
}

# ── Keep window open ──

Write-Host ""
Read-Host "  Press ENTER to close"
