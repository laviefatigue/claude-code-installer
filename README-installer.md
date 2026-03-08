# Claude Code Framework Installer

> Your creative coding journey begins with one command.

This installer sets up everything you need to start creating with Claude Code. It's designed for **everyone** — whether you've never opened a terminal before or you're a seasoned developer looking for a quick setup.

---

## What Is This?

This is a **friendly installer** that downloads and configures eight essential tools for working with Claude Code. Think of it as unpacking a creative toolkit — we handle the technical setup so you can focus on creating.

**One command. Eight tools. Ready to create.**

---

## What Gets Installed

### 1. Claude Code CLI — *The Voice*
The heart of the experience. Claude Code lives in your terminal and helps you write code, answer questions, edit files, and build projects through natural conversation.

**Why it's included:** This is what you came for — your AI coding companion.

### 2. VS Code — *The Canvas*
A free, powerful code editor where you'll write and organize your projects. It's visual, intuitive, and works beautifully with Claude.

**Why it's included:** You need somewhere to see and edit your code. VS Code is the best free option available.

### 3. Claude Extension for VS Code — *The Bridge*
Connects Claude directly into your editor. Chat with Claude, get suggestions, and work seamlessly without switching windows.

**Why it's included:** Makes Claude feel native to your workspace, not a separate tool.

### 4. Foam — *The Knowledge Web*
A note-taking system that links your thoughts together. Great for documenting projects, learning, and building a personal knowledge base.

**Why it's included:** Helps you organize what you learn and remember how you solved problems.

### 5. Node.js — *The Heartbeat*
The engine that powers Claude Code and many modern tools. It runs JavaScript outside the browser.

**Why it's included:** Required for Claude Code to function. We install it automatically if you don't have it.

### 6. Python — *The Serpent* (Optional)
A versatile programming language used in data science, automation, and countless other domains.

**Why it's included:** Many Claude Code workflows benefit from Python. Installed if not already present.

### 7. Git — *The Memory*
Version control that tracks every change you make. Never lose work, always able to go back.

**Why it's included:** Essential for any coding project. Lets you save checkpoints and collaborate.

### 8. Starter Skills — *The Scrolls*
Pre-built commands like `/help`, `/commit`, and `/review` that make common tasks instant.

**Why it's included:** Gives you superpowers from day one. Type `/help` to see what's available.

---

## Installation

### macOS & Linux
Open Terminal and paste:
```bash
curl -sL https://ccf.dev/install | sh
```

### Windows
Open PowerShell and paste:
```powershell
iwr https://ccf.dev/install.ps1 | iex
```

**Requirements:** Node.js 18 or higher (the installer will help you get it if needed).

---

## What Happens During Installation

1. **Welcome** — The installer greets you and explains what's about to happen
2. **System Check** — We look for existing tools (Node.js, Git, Python) so we don't reinstall what you have
3. **Downloads** — Missing tools are downloaded from official sources
4. **Configuration** — Everything is configured to work together seamlessly
5. **Verification** — We confirm each tool is working correctly
6. **Complete** — You're ready to start creating

The whole process typically takes 2-5 minutes depending on your internet connection and what's already installed.

---

## After Installation

Once complete, you can:

1. **Open VS Code** — Your new creative workspace
2. **Open Terminal** — Type `claude` to start talking to Claude Code
3. **Try a command** — Type `/help` to see available skills
4. **Start creating** — Ask Claude to help you build something

### First Things to Try
```
claude "Create a simple webpage that says Hello World"
claude "Help me write a Python script that organizes my downloads folder"
claude "Explain how Git works in simple terms"
```

---

## Uninstalling

If you need to remove the tools:

### Claude Code CLI
```bash
npm uninstall -g @anthropic-ai/claude-code
```

### VS Code Extensions
Open VS Code → Extensions → Find Claude/Foam → Uninstall

### Other Tools
- **VS Code:** Use your system's standard uninstall process
- **Node.js, Python, Git:** Use your system's package manager or uninstaller

---

## FAQ

### Is this safe?
Yes. The installer downloads tools from official sources (npm, Microsoft, GitHub). The code is open source — you can [review it here](https://github.com/laviefatigue/claude-code-installer).

### Do I need to know how to code?
No! Claude Code is designed to help people learn. You can describe what you want in plain English.

### What if I already have some of these tools?
The installer detects existing installations and skips them. Your current setup won't be overwritten.

### Does this cost money?
The installer and all tools are free. Claude Code usage requires an Anthropic API key (separate from this installer).

### I'm stuck / something went wrong
Open an issue on [GitHub](https://github.com/laviefatigue/claude-code-installer/issues) and we'll help you out.

### Can I install just some of the tools?
The installer is designed as a complete package, but each tool can be installed separately. Check the official docs for each:
- [Claude Code](https://github.com/anthropics/claude-code)
- [VS Code](https://code.visualstudio.com/)
- [Foam](https://foambubble.github.io/foam/)
- [Node.js](https://nodejs.org/)
- [Python](https://python.org/)
- [Git](https://git-scm.com/)

---

## Links

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Anthropic](https://anthropic.com)
- [Report an Issue](https://github.com/laviefatigue/claude-code-installer/issues)

---

Made with care for creators who want to build with AI.