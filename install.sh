#!/bin/bash
# Claude Code Framework Installer
# Run: curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash

set -e

# ═══════════════════════════════════════════════════════════════════════════════
# Color Palette (matches terminal-messages.md)
# ═══════════════════════════════════════════════════════════════════════════════

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

GOLD="\033[38;5;221m"
SAGE="\033[38;5;114m"
CORAL="\033[38;5;210m"
SAND="\033[38;5;223m"
CREAM="\033[38;5;230m"

# Symbols
CHECK="✓"
ARROW="→"
SPARKLE="✦"
DOT="·"

# ═══════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════════

write_welcome() {
    clear
    echo ""
    echo -e "${CREAM}${BOLD}"
    echo "    ┌─────────────────────────────────────────┐"
    echo "    │                                         │"
    echo "    │      Claude Code Framework              │"
    echo "    │                                         │"
    echo "    │      Your creative journey begins.      │"
    echo "    │                                         │"
    echo "    └─────────────────────────────────────────┘"
    echo -e "${RESET}"
    echo ""
    echo -e "${SAND}We're about to set up your creative toolkit.${RESET}"
    echo -e "${DIM}This usually takes 2-5 minutes.${RESET}"
    echo ""
}

write_installing() {
    local name="$1"
    local metaphor="$2"
    local why="$3"
    echo ""
    echo -e "${GOLD}${SPARKLE}${RESET} ${CREAM}${metaphor}...${RESET}"
    echo -e "${DIM}   ${name}${RESET}"
    if [ -n "$why" ]; then
        echo -e "${DIM}   ${why}${RESET}"
    fi
}

write_success() {
    local message="$1"
    local detail="$2"
    if [ -n "$detail" ]; then
        echo -e "${SAGE}${CHECK}${RESET} ${SAND}${message} ${DIM}(${detail})${RESET}"
    else
        echo -e "${SAGE}${CHECK}${RESET} ${SAND}${message}${RESET}"
    fi
}

write_already_installed() {
    local message="$1"
    local version="$2"
    if [ -n "$version" ]; then
        echo -e "${SAGE}${CHECK}${RESET} ${SAND}${message} ${DIM}${version}${RESET}"
    else
        echo -e "${SAGE}${CHECK}${RESET} ${SAND}${message}${RESET}"
    fi
}

write_skipped() {
    local message="$1"
    echo -e "${DIM}${DOT} ${message}${RESET}"
}

write_problem() {
    local message="$1"
    echo -e "${CORAL}${DOT}${RESET} ${SAND}${message}${RESET}"
}

# Track results
INSTALLED=()
SKIPPED=()
FAILED=()

# ═══════════════════════════════════════════════════════════════════════════════
# Main Installation
# ═══════════════════════════════════════════════════════════════════════════════

write_welcome
echo -e "${GOLD}${ARROW}${RESET} ${SAND}Preparing your workspace...${RESET}"
echo ""
read -p "  Press ENTER to begin " </dev/tty

# ───────────────────────────────────────────────────────────────────────────────
# 1. Homebrew (macOS only)
# ───────────────────────────────────────────────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]]; then
    write_installing "Installing Homebrew package manager" "Gathering your tools" "The foundation for installing software on macOS."

    if command -v brew &> /dev/null; then
        BREW_VERSION=$(brew --version | head -n1)
        write_already_installed "Tools gathered" "$BREW_VERSION"
        INSTALLED+=("Homebrew")
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
        if command -v brew &> /dev/null; then
            write_success "Tools gathered" "Homebrew"
            INSTALLED+=("Homebrew")
        else
            # Try to add to path for Apple Silicon
            if [ -f "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
                write_success "Tools gathered" "Homebrew"
                INSTALLED+=("Homebrew")
            else
                write_problem "Homebrew installation needs attention"
                FAILED+=("Homebrew")
            fi
        fi
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 2. Git — The Memory
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing Git version control" "Preparing your Memory" "Git tracks every change. Never lose work, always able to go back."

if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | sed 's/git version //')
    write_already_installed "Memory initialized" "Git $GIT_VERSION"
    INSTALLED+=("Git")
else
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install git 2>/dev/null || true
        write_success "Memory initialized" "Git"
        INSTALLED+=("Git")
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y git -qq
        write_success "Memory initialized" "Git"
        INSTALLED+=("Git")
    else
        write_problem "Git installation needs attention — visit git-scm.com"
        FAILED+=("Git")
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 3. Node.js — The Heartbeat
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing Node.js runtime" "Igniting the Heartbeat" "The engine that powers Claude Code and modern development tools."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    write_already_installed "Heartbeat strong" "Node.js $NODE_VERSION"
    INSTALLED+=("Node.js")
else
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install node 2>/dev/null || true
        write_success "Heartbeat strong" "Node.js"
        INSTALLED+=("Node.js")
    elif command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs -qq
        write_success "Heartbeat strong" "Node.js"
        INSTALLED+=("Node.js")
    else
        write_problem "Node.js installation needs attention"
        FAILED+=("Node.js")
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 4. Python — The Serpent (Optional)
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing Python" "Summoning ancient wisdom" "A versatile language for data science, automation, and countless workflows."

if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    write_already_installed "Wisdom acquired" "$PY_VERSION"
    INSTALLED+=("Python")
else
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install python 2>/dev/null || true
        write_success "Wisdom acquired" "Python"
        INSTALLED+=("Python")
    elif command -v apt-get &> /dev/null; then
        sudo apt-get install -y python3 python3-pip -qq
        write_success "Wisdom acquired" "Python"
        INSTALLED+=("Python")
    else
        write_skipped "Python not found — that's okay, it's optional"
        SKIPPED+=("Python")
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 5. Claude Code CLI — The Voice
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing Claude Code CLI" "Awakening the Voice" "The heart of the experience. Your AI coding companion in the terminal."

if command -v claude &> /dev/null; then
    write_already_installed "The Voice is ready" "Claude Code CLI"
    INSTALLED+=("Claude Code CLI")
else
    curl -fsSL https://claude.ai/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    if command -v claude &> /dev/null; then
        write_success "The Voice is ready" "Claude Code CLI"
        INSTALLED+=("Claude Code CLI")
    else
        write_problem "Claude Code installation needs attention"
        FAILED+=("Claude Code CLI")
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 6. VS Code — The Canvas
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Setting up VS Code" "Opening your Canvas" "A powerful editor where you'll write and organize your projects."

VSCODE_INSTALLED=false

if command -v code &> /dev/null; then
    write_already_installed "Canvas already open" "VS Code"
    INSTALLED+=("VS Code")
    VSCODE_INSTALLED=true
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
    write_already_installed "Canvas already open" "VS Code"
    INSTALLED+=("VS Code")
    VSCODE_INSTALLED=true
else
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install --cask visual-studio-code 2>/dev/null || true
        export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
        write_success "Canvas prepared" "VS Code"
        INSTALLED+=("VS Code")
        VSCODE_INSTALLED=true
    else
        write_skipped "VS Code — install manually from code.visualstudio.com"
        SKIPPED+=("VS Code")
    fi
fi

# ───────────────────────────────────────────────────────────────────────────────
# 7. Claude Extension — The Bridge
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Connecting Claude to your editor" "Building the Bridge" "Chat with Claude directly in VS Code. Context carried into your workspace."

if command -v code &> /dev/null; then
    EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    if echo "$EXTENSIONS" | grep -q "anthropic.claude-code"; then
        write_already_installed "Bridge connected" "Claude Extension"
        INSTALLED+=("Claude Extension")
    else
        code --install-extension anthropic.claude-code --force 2>/dev/null
        write_success "Bridge connected" "Claude Extension"
        INSTALLED+=("Claude Extension")
    fi
else
    write_skipped "VS Code not available — skipping extension"
    SKIPPED+=("Claude Extension")
fi

# ───────────────────────────────────────────────────────────────────────────────
# 8. Foam — The Knowledge Web
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing Foam for VS Code" "Weaving your Knowledge Web" "A note-taking system that links your thoughts. Great for documenting and learning."

if command -v code &> /dev/null; then
    EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    if echo "$EXTENSIONS" | grep -q "foam.foam-vscode"; then
        write_already_installed "Web woven" "Foam"
        INSTALLED+=("Foam")
    else
        code --install-extension foam.foam-vscode --force 2>/dev/null || true
        write_success "Web woven" "Foam"
        INSTALLED+=("Foam")
    fi
else
    write_skipped "VS Code not available — skipping Foam"
    SKIPPED+=("Foam")
fi

# ───────────────────────────────────────────────────────────────────────────────
# 9. Starter Skills — The Scrolls
# ───────────────────────────────────────────────────────────────────────────────

write_installing "Installing starter skills" "Unrolling the Scrolls" "Pre-built commands like /help and /getting-started for instant guidance."

SKILLS_DIR="$HOME/.claude/skills/getting-started"
COMMANDS_DIR="$HOME/.claude/commands"

mkdir -p "$SKILLS_DIR"
mkdir -p "$COMMANDS_DIR"

cat > "$SKILLS_DIR/SKILL.md" << 'EOF'
# Getting Started

---
name: getting-started
description: New user guide for Claude Code
user-invocable: true
---

Welcome to Claude Code! This skill helps you understand what's possible.

## What Claude Code Can Do

**Write & Edit Code**
Ask Claude to write functions, fix bugs, or refactor code in any language.

**Navigate Your Codebase**
Claude can read files, search for patterns, and understand project structure.

**Run Commands**
Execute terminal commands, run tests, and manage your development workflow.

**Learn & Explain**
Get explanations of code, concepts, or errors in plain language.

## Tips for Great Results

1. **Be specific** — "Add error handling to the login function" works better than "fix the code"
2. **Share context** — Mention the file, function, or error message
3. **Iterate** — Claude learns from your feedback in the conversation

## Try These First

- "Explain what this project does"
- "Find all TODO comments in the codebase"
- "Help me write tests for [function name]"
- "What would you improve about this code?"
EOF

cat > "$COMMANDS_DIR/help.md" << 'EOF'
# Help

Welcome to Claude Code Framework!

## Quick Start
Type `/getting-started` for a guided tour of what Claude Code can do.

## Common Commands
- `/help` — Show this help
- `/getting-started` — Interactive tutorial
- `claude` — Start a conversation with Claude

## What Claude Code Can Do
- Write and explain code in any language
- Create, edit, and organize files
- Run terminal commands
- Debug errors and suggest fixes
- Answer questions about your codebase

## Learn More
Visit: https://github.com/anthropics/claude-code
EOF

write_success "Scrolls ready" "Starter Skills"
INSTALLED+=("Starter Skills")

# ═══════════════════════════════════════════════════════════════════════════════
# Completion
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${SAGE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${CREAM}${BOLD}   Your toolkit is ready.${RESET}"
echo ""
echo -e "${SAGE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "${SAND}Everything is installed and configured.${RESET}"
echo ""

for item in "${INSTALLED[@]}"; do
    echo -e "${SAGE}${CHECK}${RESET} $item"
done

for item in "${SKIPPED[@]}"; do
    echo -e "${DIM}${DOT} $item (optional, skipped)${RESET}"
done

for item in "${FAILED[@]}"; do
    echo -e "${CORAL}${DOT}${RESET} $item ${DIM}— needs attention${RESET}"
done

echo ""
echo -e "${CREAM}What's next:${RESET}"
echo ""
echo -e "  ${GOLD}1.${RESET} ${SAND}Open a new terminal window${RESET}"
echo -e "  ${GOLD}2.${RESET} ${SAND}Type ${CREAM}claude${RESET} ${SAND}to start a conversation${RESET}"
echo -e "  ${GOLD}3.${RESET} ${SAND}Try ${CREAM}/help${RESET} ${SAND}to see available commands${RESET}"
echo ""
echo -e "${DIM}───────────────────────────────────────────${RESET}"
echo ""
echo -e "${SAND}First thing to try:${RESET}"
echo ""
echo -e "  ${CREAM}claude \"Help me create my first project\"${RESET}"
echo ""
echo -e "${DIM}───────────────────────────────────────────${RESET}"
echo ""
echo -e "${GOLD}${SPARKLE}${RESET} ${SAND}What will you create?${RESET}"
echo ""

# Optionally launch Claude Code
read -p "  Press ENTER to open Claude Code (or type 'skip' to exit): " launch </dev/tty
if [ "$launch" != "skip" ]; then
    if command -v claude &> /dev/null; then
        echo ""
        echo -e "${SAND}Opening Claude Code...${RESET}"
        claude &
    fi
fi

echo ""
