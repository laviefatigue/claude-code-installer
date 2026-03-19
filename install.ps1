# ============================================================================
# CLAUDE CODE INSTALLER (Windows)
# One command. Everything you need. Ready to create.
#
# Run: irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
# Or:  .\install.ps1
#
# What this installs:
#   REQUIRED:  Git, Node.js LTS, VS Code, Claude Code CLI
#   ESSENTIAL: Python, uv/uvx, GitHub CLI
#   CONFIGURES: git identity, ExecutionPolicy, VS Code extensions
#
# Verified URLs (2026-03-19):
#   Node.js  v24.14.0  - https://nodejs.org/dist/v24.14.0/node-v24.14.0-{x64|arm64}.msi
#   Git      latest    - https://api.github.com/repos/git-for-windows/git/releases/latest
#   Python   v3.12.13  - https://www.python.org/ftp/python/3.12.13/python-3.12.13-{amd64|arm64}.exe
#   VS Code  latest    - https://code.visualstudio.com/sha/download?build=stable&os=win32-{x64|arm64}
#   Claude   latest    - https://claude.ai/install.ps1
#   uv       latest    - https://astral.sh/uv/install.ps1
#   gh       latest    - https://api.github.com/repos/cli/cli/releases/latest ({amd64|arm64})
#   Ext      latest    - anthropic.claude-code, foam.foam-vscode
#
# ARM64/Copilot+ PCs: Architecture is auto-detected; native ARM64 installers
# are used when available in the direct-download fallback path.
#
# winget IDs: Git.Git, OpenJS.NodeJS.LTS, Microsoft.VisualStudioCode,
#             Python.Python.3.12, GitHub.cli
# ============================================================================

param(
    [switch]$Quiet,
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    Write-Host @"

Claude Code Installer for Windows

Usage:
  irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
  .\install.bat [options]          (recommended for local use)
  powershell -ExecutionPolicy Bypass -File .\install.ps1 [options]

Options:
  -Quiet    Skip all confirmations (auto-yes)
  -DryRun   Show what would be installed without making changes
  -Help     Show this help

Note: Running .\install.ps1 directly may be blocked by ExecutionPolicy.
      Use install.bat or the irm | iex method instead.

"@
    exit 0
}

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# SECTION 1: CONSTANTS & KNOWN PATHS
# ============================================================================

$INSTALLER_VERSION = "2.1.0"
$TOTAL_STEPS = 10
$tempDir = Join-Path $env:TEMP "claude-setup"

# Architecture detection for ARM64 / Copilot+ PCs
$script:IsARM64 = ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") -or ($env:PROCESSOR_IDENTIFIER -match "ARMv")

# Known install paths — don't rely solely on PATH refresh mid-session
$nodePath   = "$env:ProgramFiles\nodejs"
$nodeExe    = "$nodePath\node.exe"
$npmExe     = "$nodePath\npm.cmd"
$gitExe     = "$env:ProgramFiles\Git\cmd\git.exe"
$gitBashExe = "$env:ProgramFiles\Git\bin\bash.exe"
$codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
$codeExeAlt = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
$claudeExe  = "$env:APPDATA\npm\claude.cmd"
$claudeLocal = "$env:USERPROFILE\.local\bin\claude.exe"
$uvExe      = "$env:USERPROFILE\.local\bin\uv.exe"
$ghExe      = "$env:ProgramFiles\GitHub CLI\gh.exe"

$pythonLocations = @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:ProgramFiles\Python314\python.exe",
    "$env:ProgramFiles\Python313\python.exe",
    "$env:ProgramFiles\Python312\python.exe"
)

# Track results
$script:Installed = @()
$script:Skipped = @()
$script:Failed = @()

# ============================================================================
# SECTION 2: HELPER FUNCTIONS
# ============================================================================

function Write-BannerLine {
    param([string]$Text, [string]$Color = "Green", [int]$Indent = 0)
    # Total inner width between pipes = 55 chars
    $inner = (" " * $Indent) + $Text
    $pad = 55 - $inner.Length
    if ($pad -lt 0) { $pad = 0 }
    Write-Host "  |" -NoNewline -ForegroundColor Green
    Write-Host $inner -NoNewline -ForegroundColor $Color
    Write-Host (" " * $pad) -NoNewline
    Write-Host "|" -ForegroundColor Green
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
    Write-BannerLine "" -Color Green
    Write-BannerLine "Replace {U}niversity" -Color White -Indent 7
    Write-BannerLine "Claude Code Installer" -Color Gray -Indent 7
    Write-BannerLine "" -Color Green
    Write-BannerLine "Code is the language of technology." -Color DarkGray -Indent 3
    Write-BannerLine "With Claude, you speak it fluently." -Color DarkGray -Indent 3
    Write-BannerLine "" -Color Green
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
}

function Write-Phase {
    param([string]$Name)
    Write-Host ""
    Write-Host "  -- $Name " -NoNewline -ForegroundColor Green
    $pad = 55 - $Name.Length
    if ($pad -gt 0) { Write-Host ("-" * $pad) -ForegroundColor DarkGray }
    else { Write-Host "" }
    Write-Host ""
}

function Write-StepHeader {
    param([int]$Num, [string]$Name, [string]$Desc)
    Write-Host "  [$Num/$TOTAL_STEPS] " -NoNewline -ForegroundColor Yellow
    Write-Host $Name -ForegroundColor White
    if ($Desc) {
        Write-Host "         $Desc" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Write-Status {
    param([string]$Msg, [string]$State)
    $color = switch ($State) {
        "OK"      { "Green" }
        "SKIP"    { "Yellow" }
        "INSTALL" { "Magenta" }
        "FAIL"    { "Red" }
        "WARN"    { "Yellow" }
        "INFO"    { "Cyan" }
        default   { "White" }
    }
    Write-Host "      $Msg " -NoNewline
    Write-Host "[$State]" -ForegroundColor $color
}

function Show-Progress {
    param([int]$Percent)
    $width = 30
    $filled = [math]::Floor($width * $Percent / 100)
    $empty = $width - $filled
    $bar = ([char]0x2588).ToString() * $filled + ([char]0x2591).ToString() * $empty
    Write-Host "`r      $bar $Percent%" -NoNewline -ForegroundColor DarkCyan
    if ($Percent -ge 100) { Write-Host "" }
}

function Start-Download {
    param([string]$Url, [string]$OutFile, [int]$EstimatedSeconds = 10)

    $job = Start-Job -ScriptBlock {
        param($u, $o)
        # Enable TLS 1.2 (required) and TLS 1.3 (if available on this .NET version)
        $tlsProtocol = [Net.SecurityProtocolType]::Tls12
        try { $tlsProtocol = $tlsProtocol -bor [Net.SecurityProtocolType]::Tls13 } catch {}
        [Net.ServicePointManager]::SecurityProtocol = $tlsProtocol
        Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing
    } -ArgumentList $Url, $OutFile

    $steps = [math]::Max($EstimatedSeconds * 5, 10)
    $increment = [math]::Ceiling(100 / $steps)

    for ($i = 0; $i -le 100; $i += $increment) {
        Show-Progress -Percent ([math]::Min($i, 99))
        Start-Sleep -Milliseconds 200
        if ($job.State -eq "Completed" -or $job.State -eq "Failed") { break }
    }

    Wait-Job $job | Out-Null
    $jobState = $job.State
    Remove-Job $job

    if ($jobState -eq "Failed" -or -not (Test-Path $OutFile)) {
        Show-Progress -Percent 0
        return $false
    }

    Show-Progress -Percent 100
    return $true
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    # Also ensure known tool paths are in session
    $extraPaths = @($nodePath, "$env:APPDATA\npm", "$env:USERPROFILE\.local\bin")
    foreach ($p in $extraPaths) {
        if ((Test-Path $p) -and $env:Path -notlike "*$p*") {
            $env:Path = "$p;$env:Path"
        }
    }
}

function Test-Cmd {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-CodePath {
    if (Test-Path $codeExe) { return $codeExe }
    if (Test-Path $codeExeAlt) { return $codeExeAlt }
    $cmd = Get-Command code -EA SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Test-WingetAvailable {
    return $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
}

function Write-DryRun {
    param([string]$Msg)
    Write-Host "      [DRY RUN] " -NoNewline -ForegroundColor Magenta
    Write-Host $Msg -ForegroundColor DarkGray
}

function Install-WithWinget {
    param([string]$PackageId)
    $result = winget install $PackageId --accept-package-agreements --accept-source-agreements --silent 2>&1
    return ($LASTEXITCODE -eq 0)
}

# ============================================================================
# SECTION 3: DETECTION FUNCTIONS
# ============================================================================

function Find-Git {
    # Method 1: Known path
    if (Test-Path $gitExe) {
        $v = (& $gitExe --version 2>$null) -replace "git version ", ""
        return @{ Found = $true; Version = $v; Path = $gitExe }
    }
    # Method 2: PATH
    if (Test-Cmd "git") {
        $v = (& git --version 2>$null) -replace "git version ", ""
        return @{ Found = $true; Version = $v; Path = (Get-Command git).Source }
    }
    # Method 3: Registry
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue |
        Where-Object { $_.DisplayName -like "*Git*" -and $_.Publisher -like "*Git*" }
    if ($reg) {
        return @{ Found = $true; Version = $reg.DisplayVersion; Path = "registry" }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-Node {
    if (Test-Path $nodeExe) {
        $v = & $nodeExe --version 2>$null
        return @{ Found = $true; Version = $v; Path = $nodeExe }
    }
    if (Test-Cmd "node") {
        $v = & node --version 2>$null
        return @{ Found = $true; Version = $v; Path = (Get-Command node).Source }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-VSCode {
    $codePath = Get-CodePath
    if ($codePath) {
        $v = & $codePath --version 2>$null | Select-Object -First 1
        return @{ Found = $true; Version = $v; Path = $codePath }
    }
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue |
        Where-Object { $_.DisplayName -like "*Visual Studio Code*" }
    if ($reg) {
        return @{ Found = $true; Version = $reg.DisplayVersion; Path = "registry" }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-Claude {
    if (Test-Path $claudeLocal) {
        return @{ Found = $true; Version = "installed"; Path = $claudeLocal }
    }
    if (Test-Path $claudeExe) {
        return @{ Found = $true; Version = "installed"; Path = $claudeExe }
    }
    if (Test-Cmd "claude") {
        return @{ Found = $true; Version = "installed"; Path = (Get-Command claude).Source }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-Python {
    foreach ($loc in $pythonLocations) {
        if (Test-Path $loc) {
            $v = & $loc --version 2>$null
            return @{ Found = $true; Version = ($v -replace "Python ", ""); Path = $loc }
        }
    }
    if (Test-Cmd "python") {
        $v = & python --version 2>$null
        return @{ Found = $true; Version = ($v -replace "Python ", ""); Path = (Get-Command python).Source }
    }
    if (Test-Cmd "python3") {
        $v = & python3 --version 2>$null
        return @{ Found = $true; Version = ($v -replace "Python ", ""); Path = (Get-Command python3).Source }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-Uv {
    if (Test-Path $uvExe) {
        $v = & $uvExe --version 2>$null
        return @{ Found = $true; Version = ($v -replace "uv ", ""); Path = $uvExe }
    }
    if (Test-Cmd "uv") {
        $v = & uv --version 2>$null
        return @{ Found = $true; Version = ($v -replace "uv ", ""); Path = (Get-Command uv).Source }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

function Find-Gh {
    if (Test-Path $ghExe) {
        $v = (& $ghExe --version 2>$null) -replace "gh version ", "" -replace " .*", ""
        return @{ Found = $true; Version = $v; Path = $ghExe }
    }
    if (Test-Cmd "gh") {
        $v = (& gh --version 2>$null) -replace "gh version ", "" -replace " .*", ""
        return @{ Found = $true; Version = $v; Path = (Get-Command gh).Source }
    }
    return @{ Found = $false; Version = $null; Path = $null }
}

# ============================================================================
# SECTION 4: INSTALLATION FUNCTIONS
# ============================================================================

function Install-Git {
    Write-StepHeader 1 "Git for Windows" "Every change tracked. Undo anything. Required by Claude."

    $info = Find-Git
    if ($info.Found) {
        Write-Status "Already installed v$($info.Version)" "OK"
        $script:Installed += "Git v$($info.Version)"
    } elseif ($DryRun) {
        Write-DryRun "Would install Git via $(if (Test-WingetAvailable) { 'winget (Git.Git)' } else { 'direct download from GitHub releases' })"
        $script:Installed += "Git (dry run)"
    } else {
        Write-Status "Installing Git..." "INSTALL"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $installed = $false

        if (Test-WingetAvailable) {
            $installed = Install-WithWinget "Git.Git"
        }

        if (-not $installed) {
            $installer = Join-Path $tempDir "git.exe"
            try {
                $release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest" -UseBasicParsing
                $gitPattern = if ($script:IsARM64) { "arm64\.exe$" } else { "64-bit\.exe$" }
                $url = ($release.assets | Where-Object { $_.name -match $gitPattern }).browser_download_url
                $ok = Start-Download -Url $url -OutFile $installer -EstimatedSeconds 15
                if ($ok) {
                    Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS" -Wait
                    $installed = $true
                }
            } catch {}
        }

        Refresh-Path

        $verify = Find-Git
        if ($verify.Found) {
            Write-Status "Git installed v$($verify.Version)" "OK"
            $script:Installed += "Git v$($verify.Version)"
        } else {
            Write-Status "Git install failed - visit https://git-scm.com" "FAIL"
            $script:Failed += "Git"
            Write-Host ""
            Write-Host "      Git is required. Install it manually and re-run this script." -ForegroundColor Red
            exit 2
        }
    }

    # CRITICAL: Configure Git Bash path for Claude Code on Windows
    if (Test-Path $gitBashExe) {
        if (-not $DryRun) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBashExe, "User")
            $env:CLAUDE_CODE_GIT_BASH_PATH = $gitBashExe
        }
        Write-Status "Git Bash path $(if ($DryRun) { 'would be ' } else { '' })configured for Claude Code" "OK"
    } else {
        Write-Status "Git Bash not found at expected path" "WARN"
        Write-Host "      Claude Code may show errors. Set CLAUDE_CODE_GIT_BASH_PATH manually." -ForegroundColor DarkGray
    }

    Write-Host ""
}

function Install-Node {
    Write-StepHeader 2 "Node.js" "The engine behind Claude. Runs in the background."

    $info = Find-Node
    if ($info.Found) {
        Write-Status "Already installed $($info.Version)" "OK"
        $script:Installed += "Node.js $($info.Version)"
    } elseif ($DryRun) {
        $nodeArch = if ($script:IsARM64) { "arm64" } else { "x64" }
        Write-DryRun "Would install Node.js v24.14.0 ($nodeArch) via $(if (Test-WingetAvailable) { 'winget (OpenJS.NodeJS.LTS)' } else { "nodejs.org .msi" })"
        $script:Installed += "Node.js (dry run)"
    } else {
        Write-Status "Installing Node.js LTS..." "INSTALL"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $installed = $false

        if (Test-WingetAvailable) {
            $installed = Install-WithWinget "OpenJS.NodeJS.LTS"
        }

        if (-not $installed) {
            $installer = Join-Path $tempDir "node.msi"
            $nodeArch = if ($script:IsARM64) { "arm64" } else { "x64" }
            $nodeUrl = "https://nodejs.org/dist/v24.14.0/node-v24.14.0-$nodeArch.msi"
            $ok = Start-Download -Url $nodeUrl -OutFile $installer -EstimatedSeconds 10
            if ($ok) {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait
                $installed = $true
            }
        }

        Refresh-Path

        $verify = Find-Node
        if ($verify.Found) {
            Write-Status "Node.js installed $($verify.Version)" "OK"
            $script:Installed += "Node.js $($verify.Version)"
        } else {
            Write-Status "Node.js install failed - visit https://nodejs.org" "FAIL"
            $script:Failed += "Node.js"
            Write-Host ""
            Write-Host "      Node.js is required. Install it manually and re-run this script." -ForegroundColor Red
            exit 2
        }
    }
    Write-Host ""
}

function Install-VSCode {
    Write-StepHeader 3 "VS Code" "Your workspace. Where you and Claude build things."

    $info = Find-VSCode
    if ($info.Found) {
        Write-Status "Already installed" "OK"
        $script:Installed += "VS Code"
    } elseif ($DryRun) {
        $codeOs = if ($script:IsARM64) { "win32-arm64" } else { "win32-x64" }
        Write-DryRun "Would install VS Code ($codeOs) via $(if (Test-WingetAvailable) { 'winget (Microsoft.VisualStudioCode)' } else { 'direct download' })"
        $script:Installed += "VS Code (dry run)"
    } else {
        Write-Status "Installing VS Code..." "INSTALL"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $installed = $false

        if (Test-WingetAvailable) {
            $installed = Install-WithWinget "Microsoft.VisualStudioCode"
        }

        if (-not $installed) {
            $installer = Join-Path $tempDir "vscode.exe"
            $codeOs = if ($script:IsARM64) { "win32-arm64" } else { "win32-x64" }
            $ok = Start-Download -Url "https://code.visualstudio.com/sha/download?build=stable&os=$codeOs" -OutFile $installer -EstimatedSeconds 20
            if ($ok) {
                Start-Process $installer -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait
                Start-Sleep -Seconds 2
                $installed = $true
            }
        }

        Refresh-Path

        $verify = Find-VSCode
        if ($verify.Found) {
            Write-Status "VS Code installed" "OK"
            $script:Installed += "VS Code"
        } else {
            Write-Status "VS Code install failed - visit https://code.visualstudio.com" "FAIL"
            $script:Failed += "VS Code"
            Write-Host ""
            Write-Host "      VS Code is required. Install it manually and re-run this script." -ForegroundColor Red
            exit 2
        }
    }
    Write-Host ""
}

function Install-Claude {
    Write-StepHeader 4 "Claude Code" "Your AI builder. Describe it in English, Claude builds it."

    $info = Find-Claude
    if ($info.Found) {
        Write-Status "Already installed" "OK"
        $script:Installed += "Claude Code CLI"
    } elseif ($DryRun) {
        Write-DryRun "Would install Claude Code via official installer (claude.ai/install.ps1)"
        Write-DryRun "Fallback: npm install -g @anthropic-ai/claude-code"
        $script:Installed += "Claude Code CLI (dry run)"
    } else {
        Write-Status "Installing Claude Code..." "INSTALL"
        $installed = $false

        # Method 1: Official installer
        try {
            $installerScript = Invoke-RestMethod -Uri "https://claude.ai/install.ps1" -UseBasicParsing
            $scriptBlock = [ScriptBlock]::Create($installerScript)
            & $scriptBlock
            $installed = $true
        } catch {}

        # Method 2: npm global install (if Node is available)
        if (-not $installed -and (Test-Path $npmExe)) {
            Write-Status "Trying npm install..." "INFO"
            $env:Path = "$nodePath;$env:APPDATA\npm;$env:Path"
            & $npmExe install -g @anthropic-ai/claude-code 2>$null | Out-Null
            if (Test-Path $claudeExe) { $installed = $true }
        }

        # Method 3: npm in new process
        if (-not $installed -and (Test-Path $npmExe)) {
            $cmd = "`$env:Path = `"$nodePath;$env:APPDATA\npm;`$env:Path`"; npm install -g @anthropic-ai/claude-code"
            Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd" -Wait -WindowStyle Hidden
            if (Test-Path $claudeExe) { $installed = $true }
        }

        Refresh-Path

        $verify = Find-Claude
        if ($verify.Found) {
            Write-Status "Claude Code installed" "OK"
            $script:Installed += "Claude Code CLI"
        } else {
            Write-Status "Claude Code install failed" "FAIL"
            $script:Failed += "Claude Code CLI"
            Write-Host "      Try manually: npm install -g @anthropic-ai/claude-code" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "      Claude Code is required. Install it manually and re-run this script." -ForegroundColor Red
            exit 2
        }
    }
    Write-Host ""
}

function Install-Python {
    Write-StepHeader 5 "Python" "Automate the boring stuff. Runs while you sleep."

    $info = Find-Python
    if ($info.Found) {
        Write-Status "Already installed v$($info.Version)" "OK"
        $script:Installed += "Python v$($info.Version)"
    } elseif ($DryRun) {
        $pyArch = if ($script:IsARM64) { "arm64" } else { "amd64" }
        Write-DryRun "Would install Python 3.12.13 ($pyArch) via $(if (Test-WingetAvailable) { 'winget (Python.Python.3.12)' } else { 'python.org installer' })"
        $script:Installed += "Python (dry run)"
    } else {
        Write-Status "Installing Python..." "INSTALL"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $installed = $false

        if (Test-WingetAvailable) {
            $installed = Install-WithWinget "Python.Python.3.12"
        }

        if (-not $installed) {
            $installer = Join-Path $tempDir "python.exe"
            $pyArch = if ($script:IsARM64) { "arm64" } else { "amd64" }
            $pyUrl = "https://www.python.org/ftp/python/3.12.13/python-3.12.13-$pyArch.exe"
            $ok = Start-Download -Url $pyUrl -OutFile $installer -EstimatedSeconds 10
            if ($ok) {
                Start-Process $installer -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0" -Wait
                $installed = $true
            }
        }

        Refresh-Path

        $verify = Find-Python
        if ($verify.Found) {
            Write-Status "Python installed v$($verify.Version)" "OK"
            $script:Installed += "Python v$($verify.Version)"
        } else {
            Write-Status "Python not installed - install later from https://python.org" "WARN"
            $script:Skipped += "Python"
        }
    }
    Write-Host ""
}

function Install-Uv {
    Write-StepHeader 6 "uv" "Installs Python tools instantly. No waiting."

    $info = Find-Uv
    if ($info.Found) {
        Write-Status "Already installed v$($info.Version)" "OK"
        $script:Installed += "uv v$($info.Version)"
    } elseif ($DryRun) {
        Write-DryRun "Would install uv via official installer (astral.sh/uv/install.ps1)"
        $script:Installed += "uv (dry run)"
    } else {
        Write-Status "Installing uv..." "INSTALL"

        try {
            $installerScript = Invoke-RestMethod -Uri "https://astral.sh/uv/install.ps1" -UseBasicParsing
            $scriptBlock = [ScriptBlock]::Create($installerScript)
            & $scriptBlock
        } catch {}

        Refresh-Path

        $verify = Find-Uv
        if ($verify.Found) {
            Write-Status "uv installed v$($verify.Version)" "OK"
            $script:Installed += "uv v$($verify.Version)"
        } else {
            Write-Status "uv not installed - install later: irm https://astral.sh/uv/install.ps1 | iex" "WARN"
            $script:Skipped += "uv"
        }
    }
    Write-Host ""
}

function Install-GhCli {
    Write-StepHeader 7 "GitHub CLI" "Ship your work. Collaborate. Show it off."

    $info = Find-Gh
    if ($info.Found) {
        Write-Status "Already installed v$($info.Version)" "OK"
        $script:Installed += "GitHub CLI v$($info.Version)"
    } elseif ($DryRun) {
        $ghArch = if ($script:IsARM64) { "arm64" } else { "amd64" }
        Write-DryRun "Would install GitHub CLI ($ghArch) via $(if (Test-WingetAvailable) { 'winget (GitHub.cli)' } else { 'GitHub releases .msi' })"
        $script:Installed += "GitHub CLI (dry run)"
    } else {
        Write-Status "Installing GitHub CLI..." "INSTALL"
        $installed = $false

        if (Test-WingetAvailable) {
            $installed = Install-WithWinget "GitHub.cli"
        }

        if (-not $installed) {
            # Direct download fallback
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            $installer = Join-Path $tempDir "gh.msi"
            try {
                $release = Invoke-RestMethod "https://api.github.com/repos/cli/cli/releases/latest" -UseBasicParsing
                $ghArch = if ($script:IsARM64) { "windows_arm64" } else { "windows_amd64" }
                $url = ($release.assets | Where-Object { $_.name -match "$ghArch\.msi$" }).browser_download_url
                if ($url) {
                    $ok = Start-Download -Url $url -OutFile $installer -EstimatedSeconds 10
                    if ($ok) {
                        Start-Process "msiexec.exe" -ArgumentList "/i `"$installer`" /passive /norestart" -Wait
                        $installed = $true
                    }
                }
            } catch {}
        }

        Refresh-Path

        $verify = Find-Gh
        if ($verify.Found) {
            Write-Status "GitHub CLI installed v$($verify.Version)" "OK"
            $script:Installed += "GitHub CLI v$($verify.Version)"
        } else {
            Write-Status "GitHub CLI not installed - install later: winget install GitHub.cli" "WARN"
            $script:Skipped += "GitHub CLI"
        }
    }

    # Offer GitHub auth if gh is installed but not authenticated
    if (-not $DryRun -and -not $Quiet -and (Find-Gh).Found) {
        $authStatus = & gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "      GitHub account lets you save and share your work online." -ForegroundColor DarkGray
            Write-Host ""
            $doAuth = Read-Host "      Sign in to GitHub? (opens browser) [Y/n]"
            if ($doAuth -ne "n" -and $doAuth -ne "N") {
                Write-Status "Opening browser to sign in..." "INFO"
                & gh auth login --web --git-protocol https 2>$null
                $authCheck = & gh auth status 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Signed in to GitHub" "OK"
                } else {
                    Write-Status "GitHub auth skipped - sign in later with: gh auth login" "SKIP"
                }
            }
        } else {
            Write-Status "Already signed in to GitHub" "OK"
        }
    } elseif ($DryRun -and (Find-Gh).Found) {
        Write-DryRun "Would offer GitHub sign-in via browser (gh auth login)"
    }

    Write-Host ""
}

# ============================================================================
# SECTION 5: CONFIGURATION FUNCTIONS
# ============================================================================

function Set-GitIdentity {
    Write-StepHeader 8 "Git Identity" "So your work has your name on it."

    $currentName = & git config --global user.name 2>$null
    $currentEmail = & git config --global user.email 2>$null

    if ($currentName -and $currentEmail) {
        Write-Status "$currentName <$currentEmail>" "OK"
        $script:Installed += "Git identity"
        Write-Host ""
        return
    }

    if ($DryRun) {
        Write-DryRun "Would auto-detect from GitHub (if signed in) or prompt for name/email"
        $script:Installed += "Git identity (dry run)"
        Write-Host ""
        return
    }

    if ($Quiet) {
        # In quiet mode, try GitHub auto-detect silently
        if ((Find-Gh).Found) {
            $ghUser = & gh api user 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($ghUser) {
                if (-not $currentName -and $ghUser.name) {
                    & git config --global user.name $ghUser.name
                }
                if (-not $currentEmail -and $ghUser.login) {
                    & git config --global user.email "$($ghUser.login)@users.noreply.github.com"
                }
            }
        }
        $currentName = & git config --global user.name 2>$null
        $currentEmail = & git config --global user.email 2>$null
        if ($currentName -and $currentEmail) {
            Write-Status "$currentName <$currentEmail> (from GitHub)" "OK"
            $script:Installed += "Git identity"
        } else {
            Write-Status "Not configured (run: git config --global user.name 'Your Name')" "WARN"
            $script:Skipped += "Git identity"
        }
        Write-Host ""
        return
    }

    # Try to auto-detect from GitHub first
    $ghDetected = $false
    if ((Find-Gh).Found) {
        $ghUser = & gh api user 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($ghUser) {
            $ghName = $ghUser.name
            $ghLogin = $ghUser.login
            if ($ghName -or $ghLogin) {
                $displayName = if ($ghName) { $ghName } else { $ghLogin }
                $ghEmail = "$ghLogin@users.noreply.github.com"
                Write-Host "      Found your GitHub account: " -NoNewline -ForegroundColor DarkGray
                Write-Host "$displayName ($ghLogin)" -ForegroundColor White
                Write-Host ""

                $useGh = Read-Host "      Use this for your git identity? [Y/n]"
                if ($useGh -ne "n" -and $useGh -ne "N") {
                    if (-not $currentName) {
                        & git config --global user.name $(if ($ghName) { $ghName } else { $ghLogin })
                    }
                    if (-not $currentEmail) {
                        & git config --global user.email $ghEmail
                    }
                    $ghDetected = $true
                }
            }
        }
    }

    # Manual fallback if GitHub didn't fill everything
    if (-not $ghDetected) {
        Write-Host "      Every project needs a name attached to it." -ForegroundColor DarkGray
        Write-Host ""

        if (-not $currentName -and -not (& git config --global user.name 2>$null)) {
            $name = Read-Host "      Your name (e.g. Jane Smith)"
            if ($name) {
                & git config --global user.name $name
            }
        }

        if (-not $currentEmail -and -not (& git config --global user.email 2>$null)) {
            $email = Read-Host "      Your email (any email works)"
            if ($email) {
                & git config --global user.email $email
            }
        }
    }

    $verifyName = & git config --global user.name 2>$null
    $verifyEmail = & git config --global user.email 2>$null

    if ($verifyName -and $verifyEmail) {
        Write-Status "$verifyName <$verifyEmail>" "OK"
        $script:Installed += "Git identity"
    } else {
        Write-Status "Skipped - run later: git config --global user.name 'Your Name'" "SKIP"
        $script:Skipped += "Git identity"
    }
    Write-Host ""
}

function Set-PSExecutionPolicy {
    Write-StepHeader 9 "PowerShell ExecutionPolicy" "Unlocks your terminal. One-time fix."

    $current = Get-ExecutionPolicy -Scope CurrentUser
    if ($current -eq "Restricted" -or $current -eq "Undefined") {
        if ($DryRun) {
            Write-DryRun "Would set ExecutionPolicy from '$current' to 'RemoteSigned' (CurrentUser scope)"
            $script:Installed += "ExecutionPolicy (dry run)"
        } else {
            try {
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Write-Status "Set to RemoteSigned" "OK"
                $script:Installed += "ExecutionPolicy"
            } catch {
                Write-Status "Could not change ($current) - some tools may not work" "WARN"
                $script:Skipped += "ExecutionPolicy"
            }
        }
    } else {
        Write-Status "Already set to $current" "OK"
        $script:Installed += "ExecutionPolicy"
    }
    Write-Host ""
}

function Install-Extensions {
    Write-StepHeader 10 "VS Code Extensions" "Claude inside your editor. Ready when you are."

    $codePath = Get-CodePath
    if (-not $codePath) {
        Write-Status "VS Code not in PATH - extensions will install on first launch" "SKIP"
        $script:Skipped += "VS Code Extensions"
        Write-Host ""
        return
    }

    # Get currently installed extensions
    $extensions = & $codePath --list-extensions 2>$null

    # Claude Code extension
    if ($extensions -match "anthropic.claude-code") {
        Write-Status "Claude Code extension already installed" "OK"
    } elseif ($DryRun) {
        Write-DryRun "Would run: code --install-extension anthropic.claude-code"
    } else {
        & $codePath --install-extension anthropic.claude-code --force 2>$null | Out-Null
        Write-Status "Claude Code extension installed" "OK"
    }

    # Foam extension
    if ($extensions -match "foam.foam-vscode") {
        Write-Status "Foam extension already installed" "OK"
    } elseif ($DryRun) {
        Write-DryRun "Would run: code --install-extension foam.foam-vscode"
    } else {
        & $codePath --install-extension foam.foam-vscode --force 2>$null | Out-Null
        Write-Status "Foam extension installed" "OK"
    }

    $script:Installed += "VS Code Extensions"
    Write-Host ""
}

# ============================================================================
# SECTION 6: MAIN FLOW
# ============================================================================

# ── Phase 0: Welcome ──

Write-Banner

if ($DryRun) {
    Write-Host "  [DRY RUN MODE] No changes will be made. Showing what would happen." -ForegroundColor Magenta
    Write-Host ""
}

Write-Host "  5 minutes. 10 tools. Then you build." -ForegroundColor Gray
Write-Host "  No code required. Seriously." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What we're setting up:" -ForegroundColor White
Write-Host ""
Write-Host "    REQUIRED                            ESSENTIAL" -ForegroundColor DarkGray
Write-Host "    1. Git          " -NoNewline -ForegroundColor Green
Write-Host "track everything  " -NoNewline -ForegroundColor DarkGray
Write-Host "  5. Python     " -NoNewline -ForegroundColor Green
Write-Host "automate anything" -ForegroundColor DarkGray
Write-Host "    2. Node.js      " -NoNewline -ForegroundColor Green
Write-Host "powers Claude     " -NoNewline -ForegroundColor DarkGray
Write-Host "  6. uv         " -NoNewline -ForegroundColor Green
Write-Host "fast installs" -ForegroundColor DarkGray
Write-Host "    3. VS Code      " -NoNewline -ForegroundColor Green
Write-Host "your workspace    " -NoNewline -ForegroundColor DarkGray
Write-Host "  7. GitHub CLI " -NoNewline -ForegroundColor Green
Write-Host "ship & share" -ForegroundColor DarkGray
Write-Host "    4. Claude Code  " -NoNewline -ForegroundColor Green
Write-Host "your AI builder" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    Plus: git identity, VS Code extensions" -ForegroundColor DarkGray
Write-Host ""

if (-not $Quiet) {
    $response = Read-Host "  Ready? [Y/n]"
    if ($response -eq "n" -or $response -eq "N") {
        Write-Host ""
        Write-Host "  No worries. Run this again when you're ready to build." -ForegroundColor Gray
        Write-Host ""
        exit 0
    }
}

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# ── Phase 1: REQUIRED ──

Write-Phase "REQUIRED"

Install-Git
Install-Node
Install-VSCode
Install-Claude

# ── Phase 2: ESSENTIAL ──

Write-Phase "ESSENTIAL"

Install-Python
Install-Uv
Install-GhCli

# ── Phase 3: CONFIGURE ──

Write-Phase "CONFIGURE"

Set-GitIdentity
Set-PSExecutionPolicy
Install-Extensions

# ── Cleanup ──

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ── Summary ──

Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

if ($script:Failed.Count -eq 0) {
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
    Write-BannerLine "" -Color Green
    Write-BannerLine "You're ready to build." -Color White -Indent 12
    Write-BannerLine "Not a certificate. A toolkit." -Color DarkGray -Indent 12
    Write-BannerLine "" -Color Green
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Green
} else {
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
    Write-BannerLine "" -Color Yellow
    Write-BannerLine "Almost there." -Color White -Indent 14
    Write-BannerLine "" -Color Yellow
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Installed:" -ForegroundColor White
foreach ($item in $script:Installed) {
    Write-Host "    [OK] $item" -ForegroundColor Green
}

if ($script:Skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "  Skipped (optional):" -ForegroundColor Yellow
    foreach ($item in $script:Skipped) {
        Write-Host "    [--] $item" -ForegroundColor DarkGray
    }
}

if ($script:Failed.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed:" -ForegroundColor Red
    foreach ($item in $script:Failed) {
        Write-Host "    [!!] $item" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  What happens next:" -ForegroundColor White
Write-Host "    1. VS Code opens" -ForegroundColor Gray
Write-Host "    2. Press Ctrl+`` to open the terminal" -ForegroundColor Gray
Write-Host "    3. Type " -NoNewline -ForegroundColor Gray
Write-Host "claude" -NoNewline -ForegroundColor Green
Write-Host " and start building" -ForegroundColor Gray
Write-Host ""

if (-not $Quiet) {
    $null = Read-Host "  Press ENTER to open VS Code"
    $codePath = Get-CodePath
    if ($codePath) {
        Start-Process $codePath
    } else {
        $tryPaths = @(
            "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
            "$env:ProgramFiles\Microsoft VS Code\Code.exe"
        )
        foreach ($p in $tryPaths) {
            if (Test-Path $p) {
                Start-Process $p
                break
            }
        }
    }
    Write-Host ""
    Write-Host "  VS Code is opening. Enjoy!" -ForegroundColor Cyan
} else {
    Write-Host "  Open VS Code and type 'claude' in the terminal to begin." -ForegroundColor Cyan
}

Write-Host ""
