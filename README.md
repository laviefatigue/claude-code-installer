# Replace {U}niversity — Claude Code Installer

The community where normal people learn to build with AI.

## Install

Open your terminal, paste one line, hit Enter. The installer does the rest.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
```

### macOS / Linux (Terminal)

```bash
curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash
```

## What Gets Installed

| Tool | Purpose |
|------|---------|
| **Git** | Version control — track everything |
| **Node.js LTS** | Runtime that powers Claude Code |
| **VS Code** | Your code editor and workspace |
| **Claude Code CLI** | Your AI builder — describe it, Claude builds it |
| **uv / uvx** | Fast Python package manager |
| **GitHub CLI** | Ship and share your work |

Plus: VS Code extensions (Claude Code, Foam), git identity setup, GitHub authentication.

## Architecture Support

Both installers auto-detect CPU architecture:

- **x64** — Intel / AMD
- **ARM64** — Apple Silicon, Qualcomm Snapdragon / Copilot+ PCs

## Files

| File | Description |
|------|-------------|
| `install.ps1` | Windows installer (PowerShell) |
| `install.sh` | macOS / Linux installer (bash) |

## License

MIT
