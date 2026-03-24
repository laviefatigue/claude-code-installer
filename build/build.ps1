# ============================================================================
# Build script: Compile installer-wrapper.ps1 into ReplaceU-Claude-Setup.exe
#
# Prerequisites: Install-Module ps2exe -Scope CurrentUser
# Usage: .\build\build.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$buildDir = $PSScriptRoot

# Generate icon if missing
$iconPath = Join-Path $buildDir "replace-u.ico"
if (-not (Test-Path $iconPath)) {
    Write-Host "Generating icon..." -ForegroundColor Gray
    & (Join-Path $buildDir "create-icon.ps1")
}

# Find ps2exe
$ps2exeModule = Get-InstalledModule ps2exe -ErrorAction SilentlyContinue
if (-not $ps2exeModule) {
    Write-Host "Installing ps2exe module..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force
    $ps2exeModule = Get-InstalledModule ps2exe
}

Import-Module (Join-Path $ps2exeModule.InstalledLocation "ps2exe.psd1")

# Compile
$inputFile = Join-Path $buildDir "installer-wrapper.ps1"
$outputFile = Join-Path $buildDir "ReplaceU-Claude-Setup.exe"

Write-Host "Compiling $outputFile ..." -ForegroundColor White

Invoke-ps2exe `
    -InputFile $inputFile `
    -OutputFile $outputFile `
    -IconFile $iconPath `
    -Title "Replace University - Claude Code Setup" `
    -Description "Installs Claude Code and development tools" `
    -Company "Replace University" `
    -Product "Claude Code Setup" `
    -Version "2.3.0.0" `
    -Copyright "2026 Replace University"

$info = (Get-Item $outputFile)
Write-Host ""
Write-Host "Build complete: $outputFile ($([math]::Round($info.Length / 1KB)) KB)" -ForegroundColor Green
