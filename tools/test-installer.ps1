# ============================================================================
# INSTALLER TEST HARNESS
# Runs inside Windows Sandbox, logs everything to shared folder
# ============================================================================

$ErrorActionPreference = "Continue"
$logFile = "C:\Shared\test-results.log"
$startTime = Get-Date

function Log {
    param([string]$Msg)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $line = "[$ts] $Msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

# Start
"" | Set-Content $logFile
Log "=========================================="
Log "INSTALLER TEST HARNESS"
Log "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log "OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)"
Log "Arch: $env:PROCESSOR_ARCHITECTURE"
Log "=========================================="
Log ""

# Pre-install state
Log "--- PRE-INSTALL STATE ---"
$checks = @(
    @{ Name = "git";    Cmd = "git --version" },
    @{ Name = "node";   Cmd = "node --version" },
    @{ Name = "npm";    Cmd = "npm --version" },
    @{ Name = "python"; Cmd = "python --version" },
    @{ Name = "uv";     Cmd = "uv --version" },
    @{ Name = "gh";     Cmd = "gh --version" },
    @{ Name = "claude"; Cmd = "claude --version" },
    @{ Name = "code";   Cmd = "code --version" },
    @{ Name = "winget"; Cmd = "winget --version" },
    @{ Name = "playwright"; Cmd = "python -m playwright --version" }
)

foreach ($c in $checks) {
    $result = try { Invoke-Expression $c.Cmd 2>&1 | Select-Object -First 1 } catch { "NOT FOUND" }
    if ($LASTEXITCODE -ne 0 -and -not $result) { $result = "NOT FOUND" }
    Log "  $($c.Name): $result"
}
Log ""

# Run the installer
Log "--- RUNNING INSTALLER ---"
Log "Command: irm .../install.ps1 | iex"
Log ""

try {
    # Download and run
    $script = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1" -UseBasicParsing

    # Save a copy for inspection
    $script | Set-Content "C:\Shared\downloaded-install.ps1"
    Log "Downloaded installer saved to C:\Shared\downloaded-install.ps1"
    Log "Script length: $($script.Length) chars"
    Log ""

    # Run as subprocess but WAIT for it and capture all output
    $scriptFile = "C:\Shared\downloaded-install.ps1"
    Log "Running: powershell -File $scriptFile -Quiet"
    Log ""

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`" -Quiet"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $false

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    $stdout -split "`n" | ForEach-Object {
        $line = $_ -replace '\e\[[0-9;]*m', ''
        if ($line.Trim()) { Log "  OUT: $line" }
    }
    if ($stderr.Trim()) {
        $stderr -split "`n" | ForEach-Object {
            $line = $_ -replace '\e\[[0-9;]*m', ''
            if ($line.Trim()) { Log "  ERR: $line" }
        }
    }
    Log ""
    Log "Installer exit code: $($proc.ExitCode)"
} catch {
    Log "ERROR: $($_.Exception.Message)"
}

Log ""

# Post-install state
Log "--- POST-INSTALL STATE ---"

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

foreach ($c in $checks) {
    $result = try { Invoke-Expression $c.Cmd 2>&1 | Select-Object -First 1 } catch { "NOT FOUND" }
    if ($LASTEXITCODE -ne 0 -and -not $result) { $result = "NOT FOUND" }
    Log "  $($c.Name): $result"
}
Log ""

# Check specific paths
Log "--- INSTALL PATHS ---"
$paths = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles\nodejs\node.exe",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe",
    "$env:APPDATA\npm\claude.cmd",
    "$env:USERPROFILE\.local\bin\claude.exe",
    "$env:USERPROFILE\.local\bin\uv.exe",
    "$env:ProgramFiles\GitHub CLI\gh.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
)

foreach ($p in $paths) {
    $exists = Test-Path $p
    Log "  $(if ($exists) { 'EXISTS' } else { 'MISSING' }): $p"
}
Log ""

# Check playwright browsers
Log "--- PLAYWRIGHT BROWSERS ---"
$pwDir = "$env:LOCALAPPDATA\ms-playwright"
if (Test-Path $pwDir) {
    Get-ChildItem $pwDir -Directory | ForEach-Object { Log "  FOUND: $($_.Name)" }
} else {
    Log "  ms-playwright directory not found"
}
Log ""

# Check VS Code extensions
Log "--- VS CODE EXTENSIONS ---"
$codePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
if (-not (Test-Path $codePath)) { $codePath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd" }
if (Test-Path $codePath) {
    $exts = & $codePath --list-extensions 2>$null
    if ($exts) { $exts | ForEach-Object { Log "  EXT: $_" } }
    else { Log "  No extensions found" }
} else {
    Log "  VS Code not found for extension check"
}
Log ""

# Check git config
Log "--- GIT CONFIG ---"
$gitName = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null
Log "  user.name: $(if ($gitName) { $gitName } else { 'NOT SET' })"
Log "  user.email: $(if ($gitEmail) { $gitEmail } else { 'NOT SET' })"
Log ""

# Check ExecutionPolicy
Log "--- EXECUTION POLICY ---"
Log "  CurrentUser: $(Get-ExecutionPolicy -Scope CurrentUser)"
Log "  LocalMachine: $(Get-ExecutionPolicy -Scope LocalMachine)"
Log ""

# Summary
$elapsed = (Get-Date) - $startTime
Log "=========================================="
Log "TEST COMPLETE"
Log "Elapsed: $($elapsed.ToString('mm\:ss'))"
Log "=========================================="

# Keep window open
Write-Host ""
Write-Host "Test complete. Results saved to C:\Shared\test-results.log" -ForegroundColor Green
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
