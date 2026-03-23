@echo off
echo ============================================
echo  SANDBOX TEST LAUNCHER
echo ============================================
echo.

echo Checking mapped folders...
echo.

if exist C:\Tools\test-installer.ps1 (
    echo FOUND: C:\Tools\test-installer.ps1
) else (
    echo MISSING: C:\Tools\test-installer.ps1
    echo.
    echo Listing C:\ root...
    dir C:\ /b
    echo.
    echo Listing C:\Tools if it exists...
    if exist C:\Tools (
        dir C:\Tools /b
    ) else (
        echo C:\Tools does not exist
    )
    echo.
    echo MAPPED FOLDER FAILED. Press any key to exit.
    pause
    exit /b 1
)

if exist C:\Shared (
    echo FOUND: C:\Shared folder
) else (
    echo MISSING: C:\Shared folder - creating it
    mkdir C:\Shared
)

echo.
echo Launching test harness...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\test-installer.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo SCRIPT EXITED WITH ERROR: %ERRORLEVEL%
)

echo.
echo Press any key to close...
pause
