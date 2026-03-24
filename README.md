# Claude Code Installer

One command. Everything you need. Ready to create.

## Download & Run

No terminal required — just download and double-click:

| OS | Download | What to expect |
|----|----------|----------------|
| **Windows** | [`install-claude.bat`](https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install-claude.bat) | SmartScreen may warn — click "More info" → "Run anyway" |
| **macOS** | [`install-claude.command`](https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install-claude.command) | Right-click → "Open" → "Open" to bypass Gatekeeper |

## Terminal Alternative

If you prefer the command line:

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash
```

## What Gets Installed

| Tool | Purpose | Windows | macOS/Linux |
|------|---------|---------|-------------|
| **Git** | Version control | winget / direct download | Homebrew / apt |
| **Node.js LTS** | Runtime for Claude Code | winget / MSI | Homebrew / NodeSource |
| **VS Code** | Code editor | winget / direct download | Homebrew cask / .deb |
| **Claude Code CLI** | AI coding assistant | `claude.ai/install.ps1` | `claude.ai/install.sh` |
| **uv / uvx** | Fast Python package manager | `astral.sh/uv/install.ps1` | `astral.sh/uv/install.sh` |
| **GitHub CLI (gh)** | GitHub from the terminal | winget / direct download | Homebrew / apt |

### VS Code Extensions

- `anthropic.claude-code` — Claude Code
- `foam.foam-vscode` — Foam (linked notes)

### Configuration

The installer also configures:
- Git identity (name + email prompt)
- PowerShell ExecutionPolicy (Windows)
- Shell PATH updates (macOS/Linux)
- GitHub CLI authentication

## Architecture Support

Both installers auto-detect CPU architecture:

- **x64** (Intel/AMD) — default
- **ARM64** (Apple Silicon, Qualcomm Snapdragon / Copilot+ PCs) — native installers used when available

## Testing in Windows Sandbox

To test the installer in an isolated environment:

```powershell
# From this repo
irm https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.ps1 | iex
```

Run this inside a fresh [Windows Sandbox](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview) session for a clean-slate test.

## Files

| File | Description |
|------|-------------|
| `install-claude.bat` | Windows — download and double-click |
| `install-claude.command` | macOS — download and double-click |
| `install.ps1` | Windows PowerShell installer (full script) |
| `install.sh` | macOS/Linux bash installer (full script) |
| `install.bat` | Windows launcher (requires install.ps1 next to it) |

## License

MIT
