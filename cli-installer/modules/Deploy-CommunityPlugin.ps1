# Deploy-CommunityPlugin.ps1
# Deploys community plugin to ~/.claude/plugins/marketplaces/

function Deploy-CommunityPlugin {
    <#
    .SYNOPSIS
    Deploys a community plugin to the Claude Code plugins directory.

    .PARAMETER CommunityPath
    Path to the community directory containing .claude-plugin/plugin.json

    .OUTPUTS
    Object with PluginPath, SkillsCount, CommandsCount
    #>

    param(
        [Parameter(Mandatory)]
        [string]$CommunityPath
    )

    # Validate community path
    if (-not (Test-Path $CommunityPath)) {
        throw "Community path not found: $CommunityPath"
    }

    $pluginJsonPath = Join-Path $CommunityPath ".claude-plugin\plugin.json"
    if (-not (Test-Path $pluginJsonPath)) {
        throw "Plugin manifest not found: $pluginJsonPath"
    }

    # Load plugin config
    $pluginConfig = Get-Content $pluginJsonPath | ConvertFrom-Json
    $pluginName = $pluginConfig.name

    if (-not $pluginName) {
        throw "Plugin name not specified in plugin.json"
    }

    # Create target directories
    $claudeDir = Join-Path $env:USERPROFILE ".claude"
    $marketplacesDir = Join-Path $claudeDir "plugins\marketplaces"
    $targetDir = Join-Path $marketplacesDir $pluginName

    # Ensure directories exist
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }
    if (-not (Test-Path $marketplacesDir)) {
        New-Item -ItemType Directory -Path $marketplacesDir -Force | Out-Null
    }

    # Remove existing plugin if present
    if (Test-Path $targetDir) {
        Remove-Item $targetDir -Recurse -Force
    }

    # Copy plugin files
    Copy-Item $CommunityPath $targetDir -Recurse -Force

    # Count installed components
    $skillsCount = 0
    $commandsCount = 0

    $skillsDir = Join-Path $targetDir "skills"
    if (Test-Path $skillsDir) {
        $skillsCount = (Get-ChildItem $skillsDir -Directory).Count
    }

    $commandsDir = Join-Path $targetDir "commands"
    if (Test-Path $commandsDir) {
        $commandsCount = (Get-ChildItem $commandsDir -Filter "*.md").Count
    }

    # Also copy skills/commands to user's global config for immediate availability
    $userSkillsDir = Join-Path $claudeDir "skills"
    $userCommandsDir = Join-Path $claudeDir "commands"

    if ((Test-Path $skillsDir) -and $skillsCount -gt 0) {
        if (-not (Test-Path $userSkillsDir)) {
            New-Item -ItemType Directory -Path $userSkillsDir -Force | Out-Null
        }
        Copy-Item "$skillsDir\*" $userSkillsDir -Recurse -Force
    }

    if ((Test-Path $commandsDir) -and $commandsCount -gt 0) {
        if (-not (Test-Path $userCommandsDir)) {
            New-Item -ItemType Directory -Path $userCommandsDir -Force | Out-Null
        }
        Copy-Item "$commandsDir\*" $userCommandsDir -Recurse -Force
    }

    # Return result
    return [PSCustomObject]@{
        PluginPath = $targetDir
        PluginName = $pluginName
        SkillsCount = $skillsCount
        CommandsCount = $commandsCount
    }
}

function Get-InstalledPlugins {
    <#
    .SYNOPSIS
    Lists installed community plugins.

    .OUTPUTS
    Array of plugin info objects
    #>

    $marketplacesDir = Join-Path $env:USERPROFILE ".claude\plugins\marketplaces"

    if (-not (Test-Path $marketplacesDir)) {
        return @()
    }

    $plugins = @()
    Get-ChildItem $marketplacesDir -Directory | ForEach-Object {
        $pluginJsonPath = Join-Path $_.FullName ".claude-plugin\plugin.json"
        if (Test-Path $pluginJsonPath) {
            $config = Get-Content $pluginJsonPath | ConvertFrom-Json
            $plugins += [PSCustomObject]@{
                Name = $config.name
                Description = $config.description
                Path = $_.FullName
            }
        }
    }

    return $plugins
}

function Remove-CommunityPlugin {
    <#
    .SYNOPSIS
    Removes an installed community plugin.

    .PARAMETER PluginName
    Name of the plugin to remove
    #>

    param(
        [Parameter(Mandatory)]
        [string]$PluginName
    )

    $pluginDir = Join-Path $env:USERPROFILE ".claude\plugins\marketplaces\$PluginName"

    if (-not (Test-Path $pluginDir)) {
        throw "Plugin not found: $PluginName"
    }

    Remove-Item $pluginDir -Recurse -Force
}
