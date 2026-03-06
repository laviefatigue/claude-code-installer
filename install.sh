#!/bin/bash
# Claude Code Installer for macOS
# Run: curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo "  =========================================="
echo "        CLAUDE CODE INSTALLER (macOS)"
echo "  =========================================="
echo ""
echo "  This will install:"
echo ""
echo "    REQUIRED"
echo "    - Claude Code CLI (the AI assistant)"
echo ""
echo "    RECOMMENDED"
echo "    - Homebrew (if not installed)"
echo "    - VS Code + Extensions"
echo "      - Claude Code extension"
echo "      - Foam (knowledge graph)"
echo "    - Node.js (JavaScript runtime)"
echo "    - Python (Python runtime)"
echo "    - Starter skills (/help, /getting-started)"
echo ""
echo "  =========================================="
echo ""

read -p "  Press ENTER to start " </dev/tty

# 1. Homebrew
echo ""
echo -e "  ${CYAN}[1/7] Homebrew${NC}"
echo -e "  ${YELLOW}Package manager for macOS${NC}"
if command -v brew &> /dev/null; then
    BREW_VERSION=$(brew --version | head -n1)
    echo -e "       ${GREEN}Already installed: $BREW_VERSION${NC}"
else
    echo -n "       Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
    echo -e " ${GREEN}Done${NC}"
fi

# 2. Claude Code CLI
echo ""
echo -e "  ${CYAN}[2/7] Claude Code CLI${NC}"
echo -e "  ${YELLOW}Required - The AI assistant${NC}"
if command -v claude &> /dev/null; then
    echo -e "       ${GREEN}Already installed${NC}"
else
    echo -n "       Installing..."
    curl -fsSL https://claude.ai/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo -e " ${GREEN}Done${NC}"
fi

# 3. VS Code
echo ""
echo -e "  ${CYAN}[3/7] VS Code${NC}"
echo -e "  ${YELLOW}Code editor${NC}"
if command -v code &> /dev/null; then
    echo -e "       ${GREEN}Already installed${NC}"
elif [ -d "/Applications/Visual Studio Code.app" ]; then
    echo -e "       ${GREEN}Already installed (adding to PATH)${NC}"
    export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
else
    echo -n "       Installing..."
    if command -v brew &> /dev/null; then
        brew install --cask visual-studio-code 2>/dev/null || true
        export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
        echo -e " ${GREEN}Done${NC}"
    else
        echo -e " ${YELLOW}Skipped (install Homebrew first)${NC}"
    fi
fi

# 4. VS Code Extensions
echo ""
echo -e "  ${CYAN}[4/7] VS Code Extensions${NC}"
echo -e "  ${YELLOW}Claude Code + Foam${NC}"
if command -v code &> /dev/null; then
    EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    if echo "$EXTENSIONS" | grep -q "anthropic.claude-code"; then
        echo -e "       ${GREEN}Claude Code extension: installed${NC}"
    else
        echo -n "       Installing Claude Code extension..."
        code --install-extension anthropic.claude-code --force 2>/dev/null && echo -e " ${GREEN}Done${NC}" || echo -e " ${YELLOW}Skipped${NC}"
    fi

    if echo "$EXTENSIONS" | grep -q "foam.foam-vscode"; then
        echo -e "       ${GREEN}Foam extension: installed${NC}"
    else
        echo -n "       Installing Foam extension..."
        code --install-extension foam.foam-vscode --force 2>/dev/null && echo -e " ${GREEN}Done${NC}" || echo -e " ${YELLOW}Skipped${NC}"
    fi
else
    echo -e "       ${YELLOW}VS Code not available - skipping extensions${NC}"
fi

# 5. Node.js
echo ""
echo -e "  ${CYAN}[5/7] Node.js${NC}"
echo -e "  ${YELLOW}JavaScript runtime${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "       ${GREEN}Already installed: $NODE_VERSION${NC}"
else
    echo -n "       Installing..."
    if command -v brew &> /dev/null; then
        brew install node 2>/dev/null || true
        echo -e " ${GREEN}Done${NC}"
    else
        echo -e " ${YELLOW}Skipped${NC}"
    fi
fi

# 6. Python
echo ""
echo -e "  ${CYAN}[6/7] Python${NC}"
echo -e "  ${YELLOW}Python runtime${NC}"
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    echo -e "       ${GREEN}Already installed: $PY_VERSION${NC}"
else
    echo -n "       Installing..."
    if command -v brew &> /dev/null; then
        brew install python 2>/dev/null || true
        echo -e " ${GREEN}Done${NC}"
    else
        echo -e " ${YELLOW}Skipped${NC}"
    fi
fi

# 7. Starter skills
echo ""
echo -e "  ${CYAN}[7/7] Starter Skills${NC}"
echo -e "  ${YELLOW}/help and /getting-started commands${NC}"

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

Help new users understand what Claude Code can do: write code, edit files, run commands, and more.
EOF

cat > "$COMMANDS_DIR/help.md" << 'EOF'
# Help

Type /getting-started for a tutorial.

## What Claude Code Can Do
- Write and explain code
- Create and edit files
- Run terminal commands
- Debug errors
EOF

echo -e "       ${GREEN}Installed${NC}"

# Launch Claude Code
echo ""
echo -e "  ${CYAN}[8/7] Sign In${NC}"
echo -e "  ${YELLOW}Connect to Anthropic${NC}"
echo ""
echo "  =========================================="
echo "        SIGN IN TO ANTHROPIC"
echo "  =========================================="
echo ""
echo "  Opening Claude Code..."
echo "  Sign in with your Claude Pro, Max, or Teams account."
echo ""

sleep 2
claude &

echo ""
echo -e "  ${GREEN}=========================================="
echo "        INSTALLATION COMPLETE!"
echo "  ==========================================${NC}"
echo ""
echo "  What was installed:"
echo "    - Claude Code CLI"
echo "    - VS Code + Claude Code extension + Foam"
echo "    - Node.js"
echo "    - Python"
echo "    - Starter skills"
echo ""
echo "  To use Claude Code:"
echo "    1. Open Terminal"
echo "    2. Type: claude"
echo "    3. Start chatting!"
echo ""
echo "  =========================================="
echo ""
