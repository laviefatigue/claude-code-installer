# Claude Code - Getting Started

A friendly guided tour of Claude Code for first-time users.

## What This Extension Does

When installed, this extension opens a step-by-step walkthrough that teaches new users how to:

1. **Understand the VS Code workspace** — what's where, what does what
2. **Open a project folder** — so Claude can see their files
3. **Use the terminal** — where Claude Code lives
4. **Start Claude Code** — signing in and first conversation
5. **Have their first conversation** — example prompts and tips
6. **Discover commands** — `/help`, `/getting-started`, etc.
7. **Use the Claude sidebar** — the extension panel
8. **Start creating** — inspiration and next steps

## Installation

The Claude Code Framework installer automatically installs this extension.

To install manually:

```bash
# From the extension directory
npm install
npm run compile
code --install-extension claude-code-walkthrough-0.1.0.vsix
```

## Development

```bash
# Install dependencies
npm install

# Compile
npm run compile

# Watch for changes
npm run watch

# Package
npx vsce package
```

## Re-opening the Walkthrough

If a user wants to see the walkthrough again:

1. Open Command Palette (`Ctrl+Shift+P`)
2. Type "Claude Code: Open Getting Started Guide"
3. Press Enter

Or from the Welcome tab → "More..." → "Claude Code - Getting Started"

## Design Philosophy

This walkthrough is written for someone who has never:
- Used a terminal
- Written code
- Used VS Code

Every step assumes zero prior knowledge while respecting the user's intelligence. Technical terms are introduced gently with context.

The goal: get them from "I just installed something" to "I made something with Claude" as smoothly as possible.
