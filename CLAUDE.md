# Claude Code Framework

A modular onboarding and distribution system for Claude Code.

## Project Structure

```
claude-code-framework/
├── specs/                    # OpenSpec specifications
│   └── INSTALLER.md         # Installer requirements
├── cli-installer/           # PowerShell installer (POC)
│   ├── install.ps1          # Main entry point
│   └── modules/             # Installer modules
├── communities/             # Community configurations
│   ├── base/                # Generic setup
│   └── _template/           # Template for new communities
├── templates/               # MCP server templates
└── docs/                    # Documentation
```

## Development Guidelines

### Adding a New Community

1. Copy `communities/_template/` to `communities/[name]/`
2. Edit `.claude-plugin/plugin.json` with community info
3. Add skills to `skills/[skill-name]/SKILL.md`
4. Add commands to `commands/[name].md`
5. Test with `install.ps1 -Community [name]`

### Skill Format

Skills use YAML frontmatter:

```yaml
---
name: skill-name
description: When to use this skill
user-invocable: true
allowed-tools: Read, Glob, Grep
---

Skill instructions here...
```

### Testing the Installer

```powershell
# Test prerequisite detection
. .\cli-installer\modules\Check-Prerequisites.ps1
Test-Prerequisites

# Test plugin deployment (dry run)
. .\cli-installer\modules\Deploy-CommunityPlugin.ps1
$result = Deploy-CommunityPlugin -CommunityPath ".\communities\base"
$result
```

## Key Files

| File | Purpose |
|------|---------|
| `cli-installer/install.ps1` | Main installer script |
| `communities/base/` | Default community plugin |
| `specs/INSTALLER.md` | Installer specification |

## Related Projects

- cloudflare-plugin: Reference MCP server (Python/FastMCP)
- gemini-mcp: Reference MCP server (TypeScript)
