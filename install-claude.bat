@echo off
:: ============================================================================
:: CLAUDE CODE INSTALLER (Windows)
:: Download this file and double-click to install everything you need.
::
:: What happens:
::   1. Opens PowerShell
::   2. Downloads the installer script
::   3. Installs Git, Node.js, VS Code, Claude Code, uv, GitHub CLI
::   4. Configures your environment
::   5. Opens VS Code when done
::
:: SmartScreen may warn you - click "More info" then "Run anyway"
:: ============================================================================

echo.
echo   =============================================
echo     Claude Code Installer
echo     Setting up your development environment...
echo   =============================================
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex"

echo.
echo   =============================================
echo     Installation complete.
echo     You can close this window.
echo   =============================================
echo.
pause
