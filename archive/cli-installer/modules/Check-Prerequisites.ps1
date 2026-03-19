# Check-Prerequisites.ps1
# Checks for VS Code, Git, and other dependencies

function Test-Prerequisites {
    <#
    .SYNOPSIS
    Tests for required prerequisites and returns their status.

    .OUTPUTS
    Array of objects with Name, Installed, Version properties
    #>

    $prerequisites = @()

    # Check VS Code
    $vscode = @{
        Name = "VS Code"
        Installed = $false
        Version = $null
    }

    try {
        $vscodeVersion = & code --version 2>$null | Select-Object -First 1
        if ($vscodeVersion) {
            $vscode.Installed = $true
            $vscode.Version = $vscodeVersion
        }
    } catch {
        # Check registry as fallback
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $installed = Get-ItemProperty $regPath -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Visual Studio Code*" }

        if ($installed) {
            $vscode.Installed = $true
            $vscode.Version = $installed.DisplayVersion
        }
    }
    $prerequisites += [PSCustomObject]$vscode

    # Check Git
    $git = @{
        Name = "Git"
        Installed = $false
        Version = $null
    }

    try {
        $gitVersion = & git --version 2>$null
        if ($gitVersion -match "git version (.+)") {
            $git.Installed = $true
            $git.Version = $Matches[1]
        }
    } catch {}
    $prerequisites += [PSCustomObject]$git

    # Check Node.js (optional but useful)
    $node = @{
        Name = "Node.js"
        Installed = $false
        Version = $null
        Optional = $true
    }

    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion -match "v(.+)") {
            $node.Installed = $true
            $node.Version = $Matches[1]
        }
    } catch {}
    $prerequisites += [PSCustomObject]$node

    return $prerequisites
}

function Install-Prerequisite {
    <#
    .SYNOPSIS
    Installs a missing prerequisite using winget or direct download.

    .PARAMETER Name
    The name of the prerequisite to install (VS Code, Git, Node.js)
    #>

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Check if winget is available
    $hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

    switch ($Name) {
        "VS Code" {
            if ($hasWinget) {
                $result = winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "winget install failed: $result"
                }
            } else {
                # Direct download fallback
                $installerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
                $installerPath = Join-Path $env:TEMP "vscode-installer.exe"

                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                Start-Process -FilePath $installerPath -ArgumentList "/verysilent /mergetasks=!runcode" -Wait
                Remove-Item $installerPath -ErrorAction SilentlyContinue
            }

            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")
        }

        "Git" {
            if ($hasWinget) {
                $result = winget install Git.Git --accept-package-agreements --accept-source-agreements 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "winget install failed: $result"
                }
            } else {
                # Direct download fallback
                $gitRelease = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
                $installerUrl = ($gitRelease.assets | Where-Object { $_.name -match "64-bit\.exe$" }).browser_download_url
                $installerPath = Join-Path $env:TEMP "git-installer.exe"

                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
                Remove-Item $installerPath -ErrorAction SilentlyContinue
            }

            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")
        }

        "Node.js" {
            if ($hasWinget) {
                $result = winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "winget install failed: $result"
                }
            } else {
                # Direct download fallback
                $installerUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
                $installerPath = Join-Path $env:TEMP "node-installer.msi"

                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn" -Wait
                Remove-Item $installerPath -ErrorAction SilentlyContinue
            }

            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")
        }

        default {
            throw "Unknown prerequisite: $Name"
        }
    }
}
