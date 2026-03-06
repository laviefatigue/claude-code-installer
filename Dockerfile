# Claude Code Framework Installer - Test Container
# Uses PowerShell Core on Linux to test installer logic

FROM mcr.microsoft.com/powershell:latest

# Install basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create mock home directory structure
RUN mkdir -p /root/.claude/plugins/marketplaces \
    && mkdir -p /root/.local/bin

# Create mock 'claude' command for testing
RUN echo '#!/bin/bash\necho "Claude Code v1.0.0-mock"' > /root/.local/bin/claude \
    && chmod +x /root/.local/bin/claude

ENV PATH="/root/.local/bin:${PATH}"

# Set working directory
WORKDIR /app

# Copy installer files
COPY cli-installer/ /app/cli-installer/
COPY communities/ /app/communities/
COPY specs/ /app/specs/

# Create test script
RUN echo '#!/usr/bin/env pwsh\n\
Write-Host "=== Claude Code Framework Installer Test ===" -ForegroundColor Cyan\n\
Write-Host ""\n\
Write-Host "Step 1: Testing prerequisite detection..." -ForegroundColor Yellow\n\
. /app/cli-installer/modules/Check-Prerequisites.ps1\n\
$prereqs = Test-Prerequisites\n\
$prereqs | Format-Table -AutoSize\n\
Write-Host ""\n\
Write-Host "Step 2: Testing Claude Code detection..." -ForegroundColor Yellow\n\
. /app/cli-installer/modules/Install-ClaudeCode.ps1\n\
$installed = Test-ClaudeCode\n\
Write-Host "Claude Code installed: $installed"\n\
Write-Host ""\n\
Write-Host "Step 3: Testing plugin deployment..." -ForegroundColor Yellow\n\
. /app/cli-installer/modules/Deploy-CommunityPlugin.ps1\n\
$result = Deploy-CommunityPlugin -CommunityPath "/app/communities/base"\n\
Write-Host "Plugin deployed to: $($result.PluginPath)"\n\
Write-Host "Skills count: $($result.SkillsCount)"\n\
Write-Host "Commands count: $($result.CommandsCount)"\n\
Write-Host ""\n\
Write-Host "Step 4: Verifying deployment..." -ForegroundColor Yellow\n\
Write-Host "Contents of ~/.claude/plugins/marketplaces:"\n\
Get-ChildItem -Recurse /root/.claude/plugins/marketplaces | ForEach-Object { Write-Host "  $($_.FullName)" }\n\
Write-Host ""\n\
Write-Host "Contents of ~/.claude/skills:"\n\
Get-ChildItem -Recurse /root/.claude/skills 2>/dev/null | ForEach-Object { Write-Host "  $($_.FullName)" }\n\
Write-Host ""\n\
Write-Host "=== Test Complete ===" -ForegroundColor Green\n\
' > /app/test-installer.ps1 \
    && chmod +x /app/test-installer.ps1

# Default command runs the test
CMD ["pwsh", "/app/test-installer.ps1"]
