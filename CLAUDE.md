# Claude Code Framework

A modular onboarding and distribution system for Claude Code.

## Project Structure

```
claude-code-framework/
├── install.ps1              # Windows installer (single-file, pipeable)
├── install.sh               # macOS/Linux installer (single-file, pipeable)
├── specs/                   # Specifications
│   └── INSTALLER.md         # Installer specification v2.0
├── communities/             # Community configurations
│   ├── base/                # Generic setup
│   └── _template/           # Template for new communities
├── templates/               # MCP server templates
├── archive/                 # Previous installer versions
│   ├── install-claude-code.ps1
│   ├── Install-ClaudeCode.bat
│   └── cli-installer/
└── docs/                    # Documentation
```

## Installer

Two single-file scripts that install everything needed for Claude Code:

```powershell
# Windows
irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex

# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash
```

### What it installs (10 steps, 3 phases)

**REQUIRED:** Git, Node.js LTS, VS Code, Claude Code CLI
**ESSENTIAL:** Python, uv/uvx, GitHub CLI
**CONFIGURE:** git identity, ExecutionPolicy/PATH, VS Code extensions

See `specs/INSTALLER.md` for full specification.

## Development Guidelines

### Adding a New Community

1. Copy `communities/_template/` to `communities/[name]/`
2. Edit `.claude-plugin/plugin.json` with community info
3. Add skills to `skills/[skill-name]/SKILL.md`
4. Add commands to `commands/[name].md`

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

## Key Files

| File | Purpose |
|------|---------|
| `install.ps1` | Windows installer |
| `install.sh` | macOS/Linux installer |
| `communities/base/` | Default community plugin |
| `specs/INSTALLER.md` | Installer specification |

## Related Projects

- cloudflare-plugin: Reference MCP server (Python/FastMCP)
- gemini-mcp: Reference MCP server (TypeScript)
