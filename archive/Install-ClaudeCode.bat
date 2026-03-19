@echo off
title Claude Code Installer
color 0F

echo.
echo  ==========================================
echo         CLAUDE CODE INSTALLER
echo  ==========================================
echo.
echo  REQUIRED (Claude Code won't work without these):
echo  -------------------------------------------------
echo    [x] Git for Windows
echo        Claude Code uses Git Bash to run commands
echo.
echo    [x] Claude Code CLI
echo        The AI coding assistant itself
echo.
echo  RECOMMENDED (makes everything easier):
echo  -------------------------------------------------
echo    [+] VS Code
echo        Best editor to use with Claude Code
echo.
echo    [+] Node.js
echo        Needed for JavaScript tools and MCP servers
echo.
echo    [+] Python
echo        Needed for Python tools and MCP servers
echo.
echo  ==========================================
echo  Press any key to start installation...
pause >nul

:: ============================================
:: REQUIRED: Git for Windows
:: ============================================
echo.
echo  [1/6] Git for Windows (REQUIRED)
echo  ---------------------------------

where git >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=3" %%v in ('git --version') do echo    Already installed: %%v
) else (
    echo    Installing...
    winget install Git.Git --accept-package-agreements --accept-source-agreements --silent
    if %errorlevel%==0 (
        echo    Installed successfully.
    ) else (
        echo    ERROR: Could not install Git.
        echo    Please install manually: https://git-scm.com/downloads/win
        pause
        exit /b 1
    )
)

:: ============================================
:: REQUIRED: Claude Code CLI
:: ============================================
echo.
echo  [2/6] Claude Code CLI (REQUIRED)
echo  ---------------------------------

where claude >nul 2>nul
if %errorlevel%==0 (
    echo    Already installed.
) else (
    echo    Installing...
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
    if %errorlevel%==0 (
        echo    Installed successfully.
    ) else (
        echo    ERROR: Could not install Claude Code.
        pause
        exit /b 1
    )
)

:: ============================================
:: RECOMMENDED: VS Code
:: ============================================
echo.
echo  [3/6] VS Code (RECOMMENDED)
echo  ---------------------------------

where code >nul 2>nul
if %errorlevel%==0 (
    echo    Already installed.
) else (
    echo    Installing...
    winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent
    if %errorlevel%==0 (
        echo    Installed successfully.
    ) else (
        echo    Skipped. Install later: https://code.visualstudio.com
    )
)

:: ============================================
:: RECOMMENDED: Node.js
:: ============================================
echo.
echo  [4/6] Node.js (RECOMMENDED)
echo  ---------------------------------

where node >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=*" %%v in ('node --version') do echo    Already installed: %%v
) else (
    echo    Installing LTS version...
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent
    if %errorlevel%==0 (
        echo    Installed successfully.
    ) else (
        echo    Skipped. Install later: https://nodejs.org
    )
)

:: ============================================
:: RECOMMENDED: Python
:: ============================================
echo.
echo  [5/6] Python (RECOMMENDED)
echo  ---------------------------------

where python >nul 2>nul
if %errorlevel%==0 (
    for /f "tokens=*" %%v in ('python --version') do echo    Already installed: %%v
) else (
    echo    Installing...
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent
    if %errorlevel%==0 (
        echo    Installed successfully.
    ) else (
        echo    Skipped. Install later: https://python.org
    )
)

:: ============================================
:: STARTER SKILLS
:: ============================================
echo.
echo  [6/6] Installing starter skills...
echo  ---------------------------------

set SKILLS_DIR=%USERPROFILE%\.claude\skills\getting-started
set COMMANDS_DIR=%USERPROFILE%\.claude\commands

if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"
if not exist "%COMMANDS_DIR%" mkdir "%COMMANDS_DIR%"

(
echo # Getting Started
echo.
echo ---
echo name: getting-started
echo description: New user guide for Claude Code
echo user-invocable: true
echo ---
echo.
echo Help new users understand what Claude Code can do: write code, edit files, run commands, and more.
) > "%SKILLS_DIR%\SKILL.md"

(
echo # Help
echo.
echo Type /getting-started for a tutorial.
echo.
echo ## What Claude Code Can Do
echo - Write and explain code
echo - Create and edit files
echo - Run terminal commands
echo - Debug errors
) > "%COMMANDS_DIR%\help.md"

echo    Installed: /help, /getting-started

:: ============================================
:: AUTHENTICATION
:: ============================================
echo.
echo  ==========================================
echo         SIGN IN TO ANTHROPIC
echo  ==========================================
echo.
echo  Opening Claude Code...
echo  Sign in with your Claude Pro, Max, or Teams account.
echo.
timeout /t 2 >nul

start "" claude

echo.
echo  ==========================================
echo         INSTALLATION COMPLETE!
echo  ==========================================
echo.
echo  To start using Claude Code:
echo.
echo    Option 1: Open VS Code, press Ctrl+` then type: claude
echo    Option 2: Open Command Prompt and type: claude
echo.
echo  ==========================================
echo  Press any key to close...
pause >nul
