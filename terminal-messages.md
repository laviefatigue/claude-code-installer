# Terminal Messages — Claude Code Framework Installer

Friendly, story-driven terminal output for a non-technical audience.

---

## Color Codes Reference
```bash
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Primary Colors
GOLD="\033[38;5;221m"      # Progress, highlights
SAGE="\033[38;5;114m"      # Success
CORAL="\033[38;5;210m"     # Soft errors, warnings
SAND="\033[38;5;223m"      # Body text
CREAM="\033[38;5;230m"     # Headers

# Symbols
CHECK="✓"
ARROW="→"
SPARKLE="✦"
DOT="·"
```

---

## 1. Welcome Message (Installer Start)

```
${CREAM}${BOLD}
    ┌─────────────────────────────────────────┐
    │                                         │
    │      Claude Code Framework              │
    │                                         │
    │      Your creative journey begins.      │
    │                                         │
    └─────────────────────────────────────────┘
${RESET}

${SAND}We're about to set up your creative toolkit.${RESET}
${DIM}This usually takes 2-5 minutes.${RESET}

${GOLD}${ARROW}${RESET} ${SAND}Preparing your workspace...${RESET}

```

---

## 2. System Check Messages

Instead of technical jargon, use friendly phrases:

| Technical Term | Friendly Message |
|----------------|------------------|
| Checking Node.js version... | `${GOLD}${DOT}${RESET} ${SAND}Checking the foundations...${RESET}` |
| Node.js v20.11.0 found | `${SAGE}${CHECK}${RESET} ${SAND}Foundation ready ${DIM}(Node.js found)${RESET}` |
| Node.js not found | `${CORAL}${DOT}${RESET} ${SAND}We'll need to lay some groundwork first...${RESET}` |
| Checking Git... | `${GOLD}${DOT}${RESET} ${SAND}Looking for your memory banks...${RESET}` |
| Git found | `${SAGE}${CHECK}${RESET} ${SAND}Memory ready ${DIM}(Git found)${RESET}` |
| Checking Python... | `${GOLD}${DOT}${RESET} ${SAND}Searching for ancient wisdom...${RESET}` |
| Python found | `${SAGE}${CHECK}${RESET} ${SAND}Wisdom available ${DIM}(Python found)${RESET}` |
| Python not found | `${DIM}${DOT} Python not found — that's okay, it's optional${RESET}` |

### System Check Complete
```
${CREAM}${BOLD}System Check Complete${RESET}

${SAGE}${CHECK}${RESET} Node.js    ${DIM}v20.11.0${RESET}
${SAGE}${CHECK}${RESET} Git        ${DIM}v2.43.0${RESET}
${SAGE}${CHECK}${RESET} Python     ${DIM}v3.12.0${RESET}

${GOLD}${ARROW}${RESET} ${SAND}Your system is ready. Let's begin.${RESET}

```

---

## 3. Installation Progress Messages

### Claude Code CLI — *The Voice*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Awakening the Voice...${RESET}
${DIM}   Installing Claude Code CLI${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}The Voice is ready ${DIM}(Claude Code CLI)${RESET}
```

### VS Code — *The Canvas*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Opening your Canvas...${RESET}
${DIM}   Setting up VS Code${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Canvas prepared ${DIM}(VS Code)${RESET}
```
Already installed:
```
${SAGE}${CHECK}${RESET} ${SAND}Canvas already open ${DIM}(VS Code found)${RESET}
```

### Claude Extension — *The Bridge*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Building the Bridge...${RESET}
${DIM}   Connecting Claude to your editor${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Bridge connected ${DIM}(Claude Extension)${RESET}
```

### Foam — *The Knowledge Web*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Weaving your Knowledge Web...${RESET}
${DIM}   Installing Foam for VS Code${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Web woven ${DIM}(Foam)${RESET}
```

### Node.js — *The Heartbeat*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Igniting the Heartbeat...${RESET}
${DIM}   Installing Node.js runtime${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Heartbeat strong ${DIM}(Node.js)${RESET}
```

### Python — *The Serpent*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Summoning ancient wisdom...${RESET}
${DIM}   Installing Python${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Wisdom acquired ${DIM}(Python)${RESET}
```

### Git — *The Memory*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Preparing your Memory...${RESET}
${DIM}   Installing Git version control${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Memory initialized ${DIM}(Git)${RESET}
```

### Starter Skills — *The Scrolls*
```
${GOLD}${SPARKLE}${RESET} ${CREAM}Unrolling the Scrolls...${RESET}
${DIM}   Installing starter skills${RESET}
```
On success:
```
${SAGE}${CHECK}${RESET} ${SAND}Scrolls ready ${DIM}(Starter Skills)${RESET}
```

---

## 4. Success Messages

### Installation Complete
```

${SAGE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}

${CREAM}${BOLD}   Your toolkit is ready.${RESET}

${SAGE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}

${SAND}Everything is installed and configured.${RESET}

${CREAM}What's next:${RESET}

  ${GOLD}1.${RESET} ${SAND}Open a new terminal window${RESET}
  ${GOLD}2.${RESET} ${SAND}Type ${CREAM}claude${RESET} ${SAND}to start a conversation${RESET}
  ${GOLD}3.${RESET} ${SAND}Try ${CREAM}/help${RESET} ${SAND}to see available commands${RESET}

${DIM}───────────────────────────────────────────${RESET}

${SAND}First thing to try:${RESET}

  ${CREAM}claude "Help me create my first project"${RESET}

${DIM}───────────────────────────────────────────${RESET}

${GOLD}${SPARKLE}${RESET} ${SAND}What will you create?${RESET}

```

---

## 5. Error Messages

### General Error (Friendly)
```
${CORAL}${BOLD}Hmm, something unexpected happened.${RESET}

${SAND}Don't worry — this is usually easy to fix.${RESET}

${CREAM}What went wrong:${RESET}
${DIM}[error message here]${RESET}

${CREAM}What you can try:${RESET}
  ${GOLD}1.${RESET} ${SAND}Run the installer again${RESET}
  ${GOLD}2.${RESET} ${SAND}Check your internet connection${RESET}
  ${GOLD}3.${RESET} ${SAND}Visit ${CREAM}github.com/laviefatigue/claude-code-installer${RESET}${SAND} for help${RESET}

```

### Permission Error
```
${CORAL}${BOLD}We need a bit more access.${RESET}

${SAND}The installer needs permission to install tools.${RESET}

${CREAM}Try running with elevated permissions:${RESET}

  macOS/Linux: ${CREAM}sudo !!${RESET}
  Windows: ${CREAM}Run PowerShell as Administrator${RESET}

```

### Network Error
```
${CORAL}${BOLD}Can't reach the internet.${RESET}

${SAND}We need to download some files, but the connection isn't working.${RESET}

${CREAM}Please check:${RESET}
  ${GOLD}${DOT}${RESET} ${SAND}Your Wi-Fi or ethernet connection${RESET}
  ${GOLD}${DOT}${RESET} ${SAND}Any VPN or firewall that might block downloads${RESET}

${SAND}Then try running the installer again.${RESET}

```

### Partial Success
```
${GOLD}${BOLD}Almost there!${RESET}

${SAND}Most tools installed successfully, but a few need attention:${RESET}

${SAGE}${CHECK}${RESET} Claude Code CLI
${SAGE}${CHECK}${RESET} VS Code
${CORAL}${DOT}${RESET} ${SAND}Foam ${DIM}— try installing manually from VS Code extensions${RESET}
${SAGE}${CHECK}${RESET} Node.js
${SAGE}${CHECK}${RESET} Git

${SAND}You can still use Claude Code! The missing items are optional.${RESET}

```

---

## 6. Progress Indicators

### Spinner (for long operations)
Cycle through: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`

### Progress Bar (for downloads)
```
${GOLD}Downloading...${RESET}
[████████████░░░░░░░░] 60%
```

### Simple Dots (for quick checks)
```
${DIM}Checking${RESET}...
```

---

## Implementation Notes

1. **Use colors sparingly** — Gold for progress, Sage for success, Coral for attention
2. **Avoid technical jargon** — "Installing npm package" becomes "Preparing tools"
3. **Always show what's next** — Users should never wonder "now what?"
4. **Keep messages short** — One line when possible
5. **Use metaphors consistently** — Voice, Canvas, Bridge, etc.
6. **Add breathing room** — Empty lines between sections
7. **Test on dark and light terminals** — Colors should work in both