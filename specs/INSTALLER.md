# Installer Specification

## Overview

A PowerShell-based installer that bootstraps Claude Code for non-technical users. The installer checks/installs all prerequisites and deploys a community plugin with pre-configured skills and commands.

## Target Users

- Non-technical users who want to use Claude Code
- Users who don't understand git, npm, or terminal concepts
- Community members receiving a branded Claude Code experience

## Prerequisites

The installer must check for and optionally install:

| Prerequisite | Detection Method | Install Method | Required |
|--------------|------------------|----------------|----------|
| VS Code | `code --version` or registry | winget / direct download | Yes |
| Git for Windows | `git --version` | winget / direct download | Yes |
| Claude Code CLI | `claude --version` | `irm https://claude.ai/install.ps1 \| iex` | Yes |

## Installation Flow

### Step 1: Welcome
- Display community branding (logo, name)
- Explain what will be installed
- Request user confirmation to proceed

### Step 2: Prerequisites Check
- Check each prerequisite
- Report status (installed/missing)
- Auto-install missing prerequisites (with user consent)
- Abort if any prerequisite cannot be installed

### Step 3: Authentication
- Open browser for Anthropic authentication
- Provide manual URL if browser doesn't open
- Wait for user confirmation that auth is complete
- Verify auth by running `claude --version` (will fail pre-auth)

### Step 4: Plugin Deployment
- Create `~/.claude/plugins/marketplaces/[community]/` if needed
- Copy community plugin files (skills, commands, agents)
- Update MCP server configuration if needed

### Step 5: Completion
- Display success message
- Show quick-start instructions
- Offer to open VS Code

## Directory Structure

```
cli-installer/
├── install.ps1              # Main entry point
└── modules/
    ├── Check-Prerequisites.ps1
    ├── Install-ClaudeCode.ps1
    └── Deploy-CommunityPlugin.ps1
```

## Configuration

The installer reads community configuration from `communities/[name]/.claude-plugin/plugin.json`:

```json
{
  "name": "community-name",
  "description": "Community description",
  "branding": {
    "welcome_message": "Welcome to...",
    "logo": "assets/logo.txt"  // ASCII art for terminal
  }
}
```

## Error Handling

- **Network failure**: Retry 3 times, then abort with clear message
- **Permission denied**: Request admin privileges or guide user
- **Prerequisite install failure**: Skip and warn, or abort based on severity
- **Auth timeout**: Allow manual retry

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User cancelled |
| 2 | Prerequisites check failed |
| 3 | Installation failed |
| 4 | Authentication failed |
| 5 | Plugin deployment failed |

## Security

- No credentials stored by installer
- All downloads over HTTPS
- No elevated privileges required (user-space install)
- Plugin files are read-only after deployment

## Testing

Validation checklist:
1. [ ] Run on clean Windows 11 VM
2. [ ] Installer detects missing prerequisites
3. [ ] Prerequisites install successfully
4. [ ] Auth flow completes
5. [ ] Plugin appears in `~/.claude/plugins/marketplaces/`
6. [ ] `/getting-started` command works in Claude Code
7. [ ] Installer handles network failure gracefully
8. [ ] Installer handles user cancellation gracefully
