# Install-ClaudeCode.ps1
# Handles Claude Code CLI installation

function Test-ClaudeCode {
    <#
    .SYNOPSIS
    Tests if Claude Code CLI is installed.

    .OUTPUTS
    Boolean indicating if Claude Code is available
    #>

    try {
        $version = & claude --version 2>$null
        return $null -ne $version
    } catch {
        return $false
    }
}

function Get-ClaudeCodeVersion {
    <#
    .SYNOPSIS
    Gets the installed Claude Code version.

    .OUTPUTS
    Version string or $null if not installed
    #>

    try {
        $version = & claude --version 2>$null
        return $version
    } catch {
        return $null
    }
}

function Install-ClaudeCode {
    <#
    .SYNOPSIS
    Installs Claude Code CLI using the official installer.

    .DESCRIPTION
    Downloads and executes the official Claude Code installer script.
    This installs the native binary to ~/.local/bin/claude
    #>

    Write-Verbose "Downloading Claude Code installer..."

    # Use the official PowerShell installer
    try {
        # Download and execute the official installer
        $installerScript = Invoke-RestMethod -Uri "https://claude.ai/install.ps1" -UseBasicParsing

        # Execute the installer script
        $scriptBlock = [ScriptBlock]::Create($installerScript)
        & $scriptBlock
    } catch {
        throw "Failed to install Claude Code: $_"
    }

    # Refresh PATH to include ~/.local/bin
    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    if ($env:Path -notlike "*$localBin*") {
        $env:Path = "$localBin;$env:Path"
    }

    # Verify installation
    if (-not (Test-ClaudeCode)) {
        throw "Claude Code installation completed but binary not found. Please restart your terminal."
    }
}

function Start-ClaudeCodeAuth {
    <#
    .SYNOPSIS
    Initiates the Claude Code authentication flow.

    .DESCRIPTION
    Runs `claude` which triggers the browser-based authentication.
    Returns when the user indicates auth is complete.
    #>

    Write-Host "`nStarting Claude Code authentication..." -ForegroundColor Cyan
    Write-Host "A browser window will open for you to sign in to your Anthropic account."
    Write-Host "You need a Claude Pro, Max, or Teams subscription to use Claude Code.`n"

    # Start claude which triggers auth
    try {
        # Just running claude will prompt for auth if not authenticated
        Start-Process "claude" -NoNewWindow
    } catch {
        Write-Warning "Could not start Claude Code automatically."
        Write-Host "Please open a new terminal and run: claude"
    }
}

function Test-ClaudeCodeAuth {
    <#
    .SYNOPSIS
    Tests if Claude Code is authenticated.

    .OUTPUTS
    Boolean indicating if user is authenticated
    #>

    try {
        # Run a simple command that requires auth
        $result = & claude --help 2>$null
        # If it returns help without prompting for auth, user is authenticated
        return $result -match "Claude Code"
    } catch {
        return $false
    }
}
