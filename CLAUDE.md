# Claude Code Installer

Single-file installers for Claude Code and its development tool dependencies.

## Files

```
install.ps1    # Windows PowerShell installer
install.sh     # macOS/Linux bash installer
```

## Quick Test

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/replaceyou/claude-code-installer/master/install.ps1 | iex

# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/replaceyou/claude-code-installer/master/install.sh | bash
```

## What it installs

**REQUIRED:** Git, Node.js LTS, VS Code, Claude Code CLI
**ESSENTIAL:** uv/uvx, GitHub CLI
**CONFIGURES:** git identity, ExecutionPolicy/PATH, VS Code extensions

## Development Notes

- Both scripts are self-contained single files — no external dependencies
- Architecture auto-detection: x64 and ARM64 (Copilot+ PCs, Apple Silicon)
- Install methods: winget first, direct download as fallback (Windows); Homebrew/apt (macOS/Linux)
- All download URLs are pinned and documented in the script headers
