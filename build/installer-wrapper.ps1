# ============================================================================
# Replace University — Claude Code Installer (EXE Wrapper)
# Thin shell: downloads and runs install.ps1 seamlessly.
# The branded experience lives in install.ps1 — this just delivers it.
# ============================================================================

$host.UI.RawUI.WindowTitle = "Replace University - Claude Code Setup"

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch {}

    $installerUrl = "https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1"
    $installerScript = Invoke-RestMethod -Uri $installerUrl -UseBasicParsing

    $scriptBlock = [ScriptBlock]::Create($installerScript)
    & $scriptBlock

} catch {
    Write-Host ""
    Write-Host "  Something went wrong downloading the installer." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Check your internet connection and try again, or run" -ForegroundColor Gray
    Write-Host "  this command in PowerShell instead:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Read-Host "  Press ENTER to close"
