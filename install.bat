@echo off
:: Claude Code Installer - Windows Launcher
:: Double-click this file or run from any terminal.
:: Handles ExecutionPolicy automatically.
::
:: Flags are passed through:
::   install.bat -DryRun
::   install.bat -Quiet
::   install.bat -Help

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
