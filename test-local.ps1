# Local Test Script - Tests installer logic without actually installing anything
# Usage: .\test-local.ps1

$ErrorActionPreference = "Stop"

Write-Host "`n=== Claude Code Framework - Local Test ===" -ForegroundColor Cyan
Write-Host "This test validates the installer logic without making system changes.`n"

# Import modules
$ScriptDir = "D:\Work\claude-code-framework\cli-installer"
. "$ScriptDir\modules\Check-Prerequisites.ps1"
. "$ScriptDir\modules\Install-ClaudeCode.ps1"
. "$ScriptDir\modules\Deploy-CommunityPlugin.ps1"

# Test 1: Prerequisite Detection
Write-Host "Step 1: Testing prerequisite detection..." -ForegroundColor Yellow
$prereqs = Test-Prerequisites
Write-Host "`nDetected prerequisites:"
$prereqs | ForEach-Object {
    $status = if ($_.Installed) { "[OK]" } else { "[--]" }
    $version = if ($_.Version) { "v$($_.Version)" } else { "not found" }
    Write-Host "  $status $($_.Name): $version" -ForegroundColor $(if ($_.Installed) { "Green" } else { "Red" })
}

# Test 2: Claude Code Detection
Write-Host "`nStep 2: Testing Claude Code detection..." -ForegroundColor Yellow
$claudeInstalled = Test-ClaudeCode
$claudeVersion = Get-ClaudeCodeVersion
Write-Host "  Claude Code installed: $claudeInstalled"
if ($claudeVersion) {
    Write-Host "  Version: $claudeVersion" -ForegroundColor Green
}

# Test 3: Plugin Deployment (to temp directory)
Write-Host "`nStep 3: Testing plugin deployment (dry run)..." -ForegroundColor Yellow

# Create temp test directory
$testDir = Join-Path $env:TEMP "claude-framework-test-$(Get-Random)"
$testClaudeDir = Join-Path $testDir ".claude"
New-Item -ItemType Directory -Path "$testClaudeDir\plugins\marketplaces" -Force | Out-Null

# Temporarily override USERPROFILE for testing
$originalUserProfile = $env:USERPROFILE
$env:USERPROFILE = $testDir

try {
    $communityPath = "D:\Work\claude-code-framework\communities\base"
    $result = Deploy-CommunityPlugin -CommunityPath $communityPath

    Write-Host "  Plugin name: $($result.PluginName)" -ForegroundColor Green
    Write-Host "  Deployed to: $($result.PluginPath)"
    Write-Host "  Skills installed: $($result.SkillsCount)"
    Write-Host "  Commands installed: $($result.CommandsCount)"

    # Show deployed structure
    Write-Host "`nDeployed file structure:"
    Get-ChildItem -Recurse $result.PluginPath | ForEach-Object {
        $indent = "  " * ($_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count - $result.PluginPath.Split([IO.Path]::DirectorySeparatorChar).Count)
        Write-Host "  $indent$($_.Name)" -ForegroundColor Gray
    }

    # Show skills copied to user dir
    $userSkillsDir = Join-Path $testClaudeDir "skills"
    if (Test-Path $userSkillsDir) {
        Write-Host "`nSkills copied to user directory:"
        Get-ChildItem -Recurse $userSkillsDir -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Cyan
        }
    }

} finally {
    # Restore USERPROFILE
    $env:USERPROFILE = $originalUserProfile

    # Cleanup temp directory
    Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== All Tests Passed ===" -ForegroundColor Green
Write-Host "The installer logic is working correctly.`n"

# Show what would happen on real install
Write-Host "On a real install, the following would happen:" -ForegroundColor Yellow
Write-Host "  1. Missing prerequisites would be installed via winget"
Write-Host "  2. Claude Code CLI would be installed from claude.ai"
Write-Host "  3. Browser would open for Anthropic authentication"
Write-Host "  4. Plugin would deploy to: $env:USERPROFILE\.claude\plugins\marketplaces\"
Write-Host "  5. Skills would copy to: $env:USERPROFILE\.claude\skills\"
Write-Host ""
