# Installer Specification v2.0

## Overview

Cross-platform installer that bootstraps Claude Code for anyone. Two single-file scripts (`install.ps1` for Windows, `install.sh` for macOS/Linux) that can be piped from a URL. Installs all prerequisites, configures the environment, and gets users creating immediately.

## Target Users

- Anyone who wants to use Claude Code — writers, students, creators, developers
- Users who don't understand git, npm, or terminal concepts
- "Code is the language of technology. Now you speak it fluently."

## Install Commands

```powershell
# Windows
irm https://raw.githubusercontent.com/replaceyou/claude-code-installer/master/install.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/replaceyou/claude-code-installer/master/install.sh | bash
```

## What Gets Installed

### Phase 1: REQUIRED (abort on failure)

| Step | Tool | Why | Windows Install | macOS Install | Linux Install |
|------|------|-----|-----------------|---------------|---------------|
| 1 | Git | Version control + Git Bash (Windows) | winget / GitHub release .exe | Homebrew | apt/dnf/pacman |
| 2 | Node.js LTS | Powers Claude CLI, npx, MCP servers | winget / nodejs.org .msi | Homebrew | NodeSource + apt |
| 3 | VS Code | Primary IDE | winget / direct download | Homebrew cask | .deb / snap |
| 4 | Claude Code CLI | The AI partner | claude.ai/install.ps1, fallback npm | claude.ai/install.sh, fallback npm | Same |

### Phase 2: ESSENTIAL (warn on failure, continue)

| Step | Tool | Why | Windows Install | macOS Install | Linux Install |
|------|------|-----|-----------------|---------------|---------------|
| 5 | Python 3.12+ | MCP servers, automation, data | winget / python.org .exe | Homebrew | apt/dnf/pacman |
| 6 | uv / uvx | Python MCP server launcher | astral.sh/uv/install.ps1 | astral.sh/uv/install.sh | Same |
| 7 | GitHub CLI | PRs, issues, Actions | winget / GitHub release .msi | Homebrew | Official apt repo |

### Phase 3: CONFIGURE (best-effort, never abort)

| Step | Config | Why | Method |
|------|--------|-----|--------|
| 8 | git user.name / email | Commits fail without it | Interactive prompt (skip if --quiet) |
| 9 | ExecutionPolicy (Win) / Shell PATH (Mac/Linux) | Scripts blocked / tools not found | Set RemoteSigned / update shell rc |
| 10 | VS Code extensions | Seamless IDE experience | `code --install-extension` for anthropic.claude-code + foam.foam-vscode |

## Detection Strategy

Each tool uses multi-method detection (never rely on PATH alone):

1. **Known installation paths** — check hardcoded file paths first (works immediately after install)
2. **Command lookup** — `Get-Command` / `command -v` for PATH-based detection
3. **Registry** (Windows) — fallback for VS Code, Git
4. **Version extraction** — parse stdout to display installed version

## Installation Priority

- **Windows**: winget first (handles dependencies, PATH, updates), direct download fallback
- **macOS**: Homebrew first (installs automatically if missing), no fallback needed
- **Linux**: apt-get/dnf/pacman based on distro detection

## Windows-Specific: Git Bash Path

Claude Code on Windows requires Git Bash. The installer MUST:
1. Set `CLAUDE_CODE_GIT_BASH_PATH` as a User environment variable
2. Point it to `C:\Program Files\Git\bin\bash.exe`
3. Also set it in the current session: `$env:CLAUDE_CODE_GIT_BASH_PATH`

## Error Handling

| Tier | Steps | On Failure |
|------|-------|------------|
| REQUIRED | 1-4 | Retry download, then abort with manual install URL |
| ESSENTIAL | 5-7 | 1 attempt, warn, record in skipped list, continue |
| CONFIGURE | 8-10 | Best-effort, never abort |

## Parameters

| Flag | PowerShell | Bash | Effect |
|------|------------|------|--------|
| Quiet mode | `-Quiet` | `--quiet` / `-q` | Skip all confirmations, auto-yes |
| Help | `-Help` | `--help` / `-h` | Show usage and exit |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User cancelled |
| 2 | Required tool install failed |

## Security

- No credentials stored by installer
- All downloads over HTTPS
- No elevated privileges required on Windows (user-space install)
- macOS/Linux: `sudo` only for system package managers (apt, dnf)
- Official installers used for Claude Code and uv (passthrough to vendor scripts)

## File Structure

```
claude-code-framework/
├── install.ps1              # Windows installer (single-file)
├── install.sh               # macOS/Linux installer (single-file)
├── archive/                 # Previous installer versions
│   ├── install-claude-code.ps1
│   ├── Install-ClaudeCode.bat
│   └── cli-installer/
└── specs/
    └── INSTALLER.md         # This file
```

## Testing

### Manual Testing Matrix
- [ ] Windows 11 clean (no dev tools) — full install flow
- [ ] Windows 11 with existing tools — all detected and skipped
- [ ] macOS (Apple Silicon, clean) — Homebrew bootstrapped, full flow
- [ ] macOS with existing tools — all detected and skipped
- [ ] Ubuntu/Linux clean — apt-get flow
- [ ] `--quiet` mode on each platform
- [ ] Network failure — shows manual install URLs

### Smoke Test
1. Run installer on clean system
2. All 10 steps complete (or gracefully skip)
3. VS Code opens with Claude extension installed
4. Open terminal, type `claude` — authenticates and starts
5. `git commit` succeeds (git identity configured)
6. `npx`, `uvx`, `gh`, `python` all resolve from PATH
