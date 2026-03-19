#!/bin/bash
# ============================================================================
# CLAUDE CODE INSTALLER (macOS / Linux)
# One command. Everything you need. Ready to create.
#
# Run: curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash
# Or:  chmod +x install.sh && ./install.sh
#
# What this installs:
#   REQUIRED:  Git, Node.js LTS, VS Code, Claude Code CLI
#   ESSENTIAL: Python, uv/uvx, GitHub CLI
#   CONFIGURES: git identity, shell PATH, VS Code extensions
#
# Verified (2026-03-19):
#   Homebrew  - https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
#   NodeSource repo (apt) - manual GPG key + node_22.x repo (setup_lts.x is deprecated)
#   VS Code .deb - https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
#   Claude   - https://claude.ai/install.sh
#   uv       - https://astral.sh/uv/install.sh
#   gh (apt) - https://cli.github.com/packages/githubcli-archive-keyring.gpg
#   Brew pkgs: git, node, python, gh, visual-studio-code (cask)
# ============================================================================

set -e

# ============================================================================
# SECTION 1: CONSTANTS & COLORS
# ============================================================================

INSTALLER_VERSION="2.1.0"
TOTAL_STEPS=10

# ANSI color palette
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Replace {U}niversity palette — lime green accent, dark/light contrast
LIME="\033[38;5;154m"
SAGE="\033[38;5;114m"
CORAL="\033[38;5;210m"
SAND="\033[38;5;223m"
CREAM="\033[38;5;230m"
CYAN="\033[38;5;117m"
GRAY="\033[38;5;245m"

CHECK="✓"
CROSS="✗"
ARROW="→"
WARN="!"

# Detect OS
OS="unknown"
PKG_MANAGER="none"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    PKG_MANAGER="brew"
elif [[ -f /etc/debian_version ]] || command -v apt-get &>/dev/null; then
    OS="linux"
    PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then
    OS="linux"
    PKG_MANAGER="dnf"
elif command -v pacman &>/dev/null; then
    OS="linux"
    PKG_MANAGER="pacman"
else
    OS="linux"
    PKG_MANAGER="unknown"
fi

# Parse flags
QUIET=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --quiet|-q) QUIET=true ;;
        --dry-run|-n) DRY_RUN=true ;;
        --help|-h)
            echo ""
            echo "Claude Code Installer for macOS/Linux"
            echo ""
            echo "Usage:"
            echo "  curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash"
            echo "  ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --quiet, -q      Skip all confirmations"
            echo "  --dry-run, -n    Show what would be installed without making changes"
            echo "  --help, -h       Show this help"
            echo ""
            exit 0
            ;;
    esac
done

# Track results
INSTALLED=()
SKIPPED=()
FAILED=()

# ============================================================================
# SECTION 2: HELPER FUNCTIONS
# ============================================================================

write_banner() {
    clear
    echo ""
    echo -e "${LIME}${BOLD}  +-------------------------------------------------------+${RESET}"
    echo -e "${LIME}${BOLD}  |                                                       |${RESET}"
    echo -e "${LIME}${BOLD}  |        ${RESET}${CREAM}${BOLD}Replace {U}niversity${RESET}${LIME}${BOLD}                       |${RESET}"
    echo -e "${LIME}${BOLD}  |        ${RESET}${GRAY}Claude Code Installer${LIME}${BOLD}                        |${RESET}"
    echo -e "${LIME}${BOLD}  |                                                       |${RESET}"
    echo -e "${LIME}${BOLD}  |    ${RESET}${GRAY}Code is the language of technology.${LIME}${BOLD}            |${RESET}"
    echo -e "${LIME}${BOLD}  |    ${RESET}${GRAY}With Claude, you speak it fluently.${LIME}${BOLD}           |${RESET}"
    echo -e "${LIME}${BOLD}  |                                                       |${RESET}"
    echo -e "${LIME}${BOLD}  +-------------------------------------------------------+${RESET}"
    echo ""
}

write_phase() {
    local name="$1"
    echo ""
    echo -e "${LIME}  -- ${name} $(printf '%0.s-' $(seq 1 $((55 - ${#name}))))${RESET}"
    echo ""
}

write_step_header() {
    local num="$1"
    local name="$2"
    local desc="$3"
    echo -e "${GOLD}  [${num}/${TOTAL_STEPS}] ${RESET}${CREAM}${BOLD}${name}${RESET}"
    if [ -n "$desc" ]; then
        echo -e "${DIM}         ${desc}${RESET}"
    fi
    echo ""
}

write_status() {
    local msg="$1"
    local state="$2"
    case "$state" in
        OK)      echo -e "      ${SAGE}${CHECK}${RESET} ${SAND}${msg}${RESET}" ;;
        INSTALL) echo -e "      ${CYAN}${ARROW}${RESET} ${SAND}${msg}${RESET}" ;;
        FAIL)    echo -e "      ${CORAL}${CROSS}${RESET} ${SAND}${msg}${RESET}" ;;
        WARN)    echo -e "      ${GOLD}${WARN}${RESET} ${SAND}${msg}${RESET}" ;;
        SKIP)    echo -e "      ${DIM}- ${msg}${RESET}" ;;
        INFO)    echo -e "      ${CYAN}${ARROW}${RESET} ${DIM}${msg}${RESET}" ;;
    esac
}

write_dry_run() {
    local msg="$1"
    echo -e "      ${BOLD}[DRY RUN]${RESET} ${DIM}${msg}${RESET}"
}

install_with_brew() {
    local formula="$1"
    local cask="$2"
    if [ "$cask" = "cask" ]; then
        brew install --cask "$formula" 2>/dev/null
    else
        brew install "$formula" 2>/dev/null
    fi
}

install_with_apt() {
    local pkg="$1"
    sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y "$pkg" -qq 2>/dev/null
}

install_with_dnf() {
    local pkg="$1"
    sudo dnf install -y "$pkg" 2>/dev/null
}

install_with_pacman() {
    local pkg="$1"
    sudo pacman -S --noconfirm "$pkg" 2>/dev/null
}

install_pkg() {
    local brew_name="$1"
    local apt_name="$2"
    local dnf_name="${3:-$apt_name}"
    local pacman_name="${4:-$apt_name}"
    local is_cask="${5:-}"

    case "$PKG_MANAGER" in
        brew)    install_with_brew "$brew_name" "$is_cask" ;;
        apt)     install_with_apt "$apt_name" ;;
        dnf)     install_with_dnf "$dnf_name" ;;
        pacman)  install_with_pacman "$pacman_name" ;;
        *)       return 1 ;;
    esac
}

# ============================================================================
# SECTION 3: INSTALLATION FUNCTIONS
# ============================================================================

ensure_homebrew() {
    if [[ "$OS" != "macos" ]]; then return 0; fi
    if command -v brew &>/dev/null; then return 0; fi

    echo -e "${CYAN}  [0] ${RESET}${CREAM}${BOLD}Homebrew${RESET}"
    echo -e "${DIM}         Package manager for macOS (required to install other tools).${RESET}"
    echo ""
    write_status "Installing Homebrew..." "INSTALL"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty

    # Add Homebrew to PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
        write_status "Homebrew installed" "OK"
    else
        write_status "Homebrew install failed - visit https://brew.sh" "FAIL"
        FAILED+=("Homebrew")
    fi
    echo ""
}

install_git() {
    write_step_header 1 "Git" "Every change tracked. Undo anything."

    if command -v git &>/dev/null; then
        local v
        v=$(git --version | sed 's/git version //')
        write_status "Already installed v${v}" "OK"
        INSTALLED+=("Git v${v}")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install Git via $PKG_MANAGER"
        INSTALLED+=("Git (dry run)")
    else
        write_status "Installing Git..." "INSTALL"

        install_pkg "git" "git" "git" "git"

        if command -v git &>/dev/null; then
            local v
            v=$(git --version | sed 's/git version //')
            write_status "Git installed v${v}" "OK"
            INSTALLED+=("Git v${v}")
        else
            write_status "Git install failed - visit https://git-scm.com" "FAIL"
            FAILED+=("Git")
            echo ""
            echo -e "      ${CORAL}Git is required. Install it manually and re-run this script.${RESET}"
            exit 2
        fi
    fi
    echo ""
}

install_node() {
    write_step_header 2 "Node.js" "The engine behind Claude. Runs in the background."

    if command -v node &>/dev/null; then
        local v
        v=$(node --version)
        write_status "Already installed ${v}" "OK"
        INSTALLED+=("Node.js ${v}")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install Node.js LTS via $PKG_MANAGER"
        INSTALLED+=("Node.js (dry run)")
    else
        write_status "Installing Node.js LTS..." "INSTALL"
        local installed=false

        if [[ "$PKG_MANAGER" == "brew" ]]; then
            brew install node 2>/dev/null && installed=true
        elif [[ "$PKG_MANAGER" == "apt" ]]; then
            # NodeSource manual repo setup (setup_lts.x scripts are deprecated)
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
            sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y nodejs -qq 2>/dev/null && installed=true
        elif [[ "$PKG_MANAGER" == "dnf" ]]; then
            sudo dnf install -y nodejs 2>/dev/null && installed=true
        elif [[ "$PKG_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm nodejs npm 2>/dev/null && installed=true
        fi

        if command -v node &>/dev/null; then
            local v
            v=$(node --version)
            write_status "Node.js installed ${v}" "OK"
            INSTALLED+=("Node.js ${v}")
        else
            write_status "Node.js install failed - visit https://nodejs.org" "FAIL"
            FAILED+=("Node.js")
            echo ""
            echo -e "      ${CORAL}Node.js is required. Install it manually and re-run this script.${RESET}"
            exit 2
        fi
    fi
    echo ""
}

install_vscode() {
    write_step_header 3 "VS Code" "Your workspace. Where you and Claude build things."

    if command -v code &>/dev/null; then
        write_status "Already installed" "OK"
        INSTALLED+=("VS Code")
    elif [[ "$OS" == "macos" ]] && [ -d "/Applications/Visual Studio Code.app" ]; then
        export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
        write_status "Already installed" "OK"
        INSTALLED+=("VS Code")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install VS Code via $([ "$PKG_MANAGER" = "brew" ] && echo "brew cask" || echo "$PKG_MANAGER / .deb download")"
        INSTALLED+=("VS Code (dry run)")
    else
        write_status "Installing VS Code..." "INSTALL"

        if [[ "$PKG_MANAGER" == "brew" ]]; then
            brew install --cask visual-studio-code 2>/dev/null
            export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
        elif [[ "$PKG_MANAGER" == "apt" ]]; then
            # Download .deb directly
            local tmp_deb="/tmp/vscode.deb"
            curl -fsSL "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o "$tmp_deb"
            sudo dpkg -i "$tmp_deb" 2>/dev/null || sudo apt-get install -f -y -qq 2>/dev/null
            rm -f "$tmp_deb"
        elif command -v snap &>/dev/null; then
            sudo snap install --classic code 2>/dev/null
        fi

        if command -v code &>/dev/null; then
            write_status "VS Code installed" "OK"
            INSTALLED+=("VS Code")
        else
            write_status "VS Code install failed - visit https://code.visualstudio.com" "FAIL"
            FAILED+=("VS Code")
            echo ""
            echo -e "      ${CORAL}VS Code is required. Install it manually and re-run this script.${RESET}"
            exit 2
        fi
    fi
    echo ""
}

install_claude() {
    write_step_header 4 "Claude Code" "Your AI builder. Describe it in English, Claude builds it."

    if command -v claude &>/dev/null; then
        write_status "Already installed" "OK"
        INSTALLED+=("Claude Code CLI")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install Claude Code via official installer (claude.ai/install.sh)"
        write_dry_run "Fallback: npm install -g @anthropic-ai/claude-code"
        INSTALLED+=("Claude Code CLI (dry run)")
    else
        write_status "Installing Claude Code..." "INSTALL"

        # Official installer
        curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null
        export PATH="$HOME/.local/bin:$PATH"

        if command -v claude &>/dev/null; then
            write_status "Claude Code installed" "OK"
            INSTALLED+=("Claude Code CLI")
        else
            # Fallback: npm global install
            if command -v npm &>/dev/null; then
                write_status "Trying npm install..." "INFO"
                npm install -g @anthropic-ai/claude-code 2>/dev/null
            fi

            if command -v claude &>/dev/null; then
                write_status "Claude Code installed" "OK"
                INSTALLED+=("Claude Code CLI")
            else
                write_status "Claude Code install failed" "FAIL"
                FAILED+=("Claude Code CLI")
                echo -e "${DIM}      Try manually: npm install -g @anthropic-ai/claude-code${RESET}"
                echo ""
                echo -e "      ${CORAL}Claude Code is required. Install it manually and re-run this script.${RESET}"
                exit 2
            fi
        fi
    fi
    echo ""
}

install_python() {
    write_step_header 5 "Python" "Automate the boring stuff. Runs while you sleep."

    if command -v python3 &>/dev/null; then
        local v
        v=$(python3 --version 2>/dev/null | sed 's/Python //')
        write_status "Already installed v${v}" "OK"
        INSTALLED+=("Python v${v}")
    elif command -v python &>/dev/null; then
        local v
        v=$(python --version 2>/dev/null | sed 's/Python //')
        write_status "Already installed v${v}" "OK"
        INSTALLED+=("Python v${v}")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install Python via $PKG_MANAGER"
        INSTALLED+=("Python (dry run)")
    else
        write_status "Installing Python..." "INSTALL"

        install_pkg "python" "python3" "python3" "python"

        # Also install pip on Linux
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            sudo apt-get install -y python3-pip -qq 2>/dev/null
        fi

        if command -v python3 &>/dev/null; then
            local v
            v=$(python3 --version 2>/dev/null | sed 's/Python //')
            write_status "Python installed v${v}" "OK"
            INSTALLED+=("Python v${v}")
        else
            write_status "Python not installed - install later from https://python.org" "WARN"
            SKIPPED+=("Python")
        fi
    fi
    echo ""
}

install_uv() {
    write_step_header 6 "uv" "Installs Python tools instantly. No waiting."

    if command -v uv &>/dev/null; then
        local v
        v=$(uv --version 2>/dev/null | sed 's/uv //')
        write_status "Already installed v${v}" "OK"
        INSTALLED+=("uv v${v}")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install uv via official installer (astral.sh/uv/install.sh)"
        INSTALLED+=("uv (dry run)")
    else
        write_status "Installing uv..." "INSTALL"

        curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null
        export PATH="$HOME/.local/bin:$PATH"

        if command -v uv &>/dev/null; then
            local v
            v=$(uv --version 2>/dev/null | sed 's/uv //')
            write_status "uv installed v${v}" "OK"
            INSTALLED+=("uv v${v}")
        else
            write_status "uv not installed - install later: curl -LsSf https://astral.sh/uv/install.sh | sh" "WARN"
            SKIPPED+=("uv")
        fi
    fi
    echo ""
}

install_gh() {
    write_step_header 7 "GitHub CLI" "Ship your work. Collaborate. Show it off."

    if command -v gh &>/dev/null; then
        local v
        v=$(gh --version 2>/dev/null | head -1 | sed 's/gh version //' | sed 's/ .*//')
        write_status "Already installed v${v}" "OK"
        INSTALLED+=("GitHub CLI v${v}")
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would install GitHub CLI via $PKG_MANAGER"
        INSTALLED+=("GitHub CLI (dry run)")
    else
        write_status "Installing GitHub CLI..." "INSTALL"

        if [[ "$PKG_MANAGER" == "brew" ]]; then
            brew install gh 2>/dev/null
        elif [[ "$PKG_MANAGER" == "apt" ]]; then
            # Official GitHub CLI apt repo (keyring persisted to /etc/apt/keyrings/)
            (type -p wget >/dev/null || (sudo apt-get update -qq && sudo apt-get install wget -y -qq)) \
                && sudo mkdir -p -m 755 /etc/apt/keyrings \
                && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
                && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
                && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
                && sudo apt-get update -qq \
                && sudo apt-get install gh -y -qq 2>/dev/null
        elif [[ "$PKG_MANAGER" == "dnf" ]]; then
            sudo dnf install -y gh 2>/dev/null
        elif [[ "$PKG_MANAGER" == "pacman" ]]; then
            sudo pacman -S --noconfirm github-cli 2>/dev/null
        fi

        if command -v gh &>/dev/null; then
            local v
            v=$(gh --version 2>/dev/null | head -1 | sed 's/gh version //' | sed 's/ .*//')
            write_status "GitHub CLI installed v${v}" "OK"
            INSTALLED+=("GitHub CLI v${v}")
        else
            write_status "GitHub CLI not installed - visit https://cli.github.com" "WARN"
            SKIPPED+=("GitHub CLI")
        fi
    fi
    echo ""
}

# ============================================================================
# SECTION 4: CONFIGURATION FUNCTIONS
# ============================================================================

set_git_identity() {
    write_step_header 8 "Git Identity" "So your work has your name on it."

    local current_name current_email
    current_name=$(git config --global user.name 2>/dev/null)
    current_email=$(git config --global user.email 2>/dev/null)

    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        write_status "${current_name} <${current_email}>" "OK"
        INSTALLED+=("Git identity")
        echo ""
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        write_dry_run "Would prompt for name and email, then run: git config --global user.name/email"
        INSTALLED+=("Git identity (dry run)")
        echo ""
        return
    fi

    if [ "$QUIET" = true ]; then
        write_status "Not configured (run: git config --global user.name 'Your Name')" "WARN"
        SKIPPED+=("Git identity")
        echo ""
        return
    fi

    echo -e "${DIM}      Git needs to know your name so your work is attributed to you.${RESET}"
    echo ""

    if [ -z "$current_name" ]; then
        read -p "      Your name (e.g. Jane Smith): " name </dev/tty
        if [ -n "$name" ]; then
            git config --global user.name "$name"
        fi
    fi

    if [ -z "$current_email" ]; then
        read -p "      Your email: " email </dev/tty
        if [ -n "$email" ]; then
            git config --global user.email "$email"
        fi
    fi

    local verify_name verify_email
    verify_name=$(git config --global user.name 2>/dev/null)
    verify_email=$(git config --global user.email 2>/dev/null)

    if [ -n "$verify_name" ] && [ -n "$verify_email" ]; then
        write_status "${verify_name} <${verify_email}>" "OK"
        INSTALLED+=("Git identity")
    else
        write_status "Skipped - configure later: git config --global user.name 'Your Name'" "SKIP"
        SKIPPED+=("Git identity")
    fi
    echo ""
}

ensure_shell_path() {
    write_step_header 9 "Shell PATH" "Making sure everything just works."

    local local_bin="$HOME/.local/bin"
    local path_updated=false

    # Check which shell rc file to update
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ]; then
        shell_rc="$HOME/.bashrc"
        # macOS uses .bash_profile
        if [[ "$OS" == "macos" ]] && [ -f "$HOME/.bash_profile" ]; then
            shell_rc="$HOME/.bash_profile"
        fi
    fi

    # Ensure shell rc file exists
    if [ -n "$shell_rc" ] && [ ! -f "$shell_rc" ]; then
        if [ "$DRY_RUN" != true ]; then
            touch "$shell_rc"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        if [[ ":$PATH:" != *":$local_bin:"* ]]; then
            write_dry_run "Would add ~/.local/bin to PATH in ${shell_rc:-'(unknown shell rc)'}"
        fi
        if [[ "$OS" == "macos" ]]; then
            write_dry_run "Would ensure Homebrew shellenv in ${shell_rc:-'(unknown shell rc)'}"
        fi
        write_status "PATH check complete" "OK"
    else
        # Ensure ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$local_bin:"* ]]; then
            export PATH="$local_bin:$PATH"
            if [ -n "$shell_rc" ]; then
                if ! grep -q "\.local/bin" "$shell_rc" 2>/dev/null; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
                    path_updated=true
                fi
            fi
        fi

        # macOS: Ensure Homebrew is in PATH (Apple Silicon or Intel)
        if [[ "$OS" == "macos" ]]; then
            if [ -f "/opt/homebrew/bin/brew" ]; then
                if [ -n "$shell_rc" ] && ! grep -q "homebrew" "$shell_rc" 2>/dev/null; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$shell_rc"
                    path_updated=true
                fi
            elif [ -f "/usr/local/bin/brew" ]; then
                if [ -n "$shell_rc" ] && ! grep -q "homebrew" "$shell_rc" 2>/dev/null; then
                    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$shell_rc"
                    path_updated=true
                fi
            fi
        fi

        if [ "$path_updated" = true ]; then
            write_status "Updated ${shell_rc}" "OK"
        else
            write_status "PATH already configured" "OK"
        fi
    fi
    INSTALLED+=("Shell PATH")
    echo ""
}

install_extensions() {
    write_step_header 10 "VS Code Extensions" "Claude inside your editor. Ready when you are."

    if ! command -v code &>/dev/null; then
        write_status "VS Code not in PATH - extensions will install on first launch" "SKIP"
        SKIPPED+=("VS Code Extensions")
        echo ""
        return
    fi

    local extensions
    extensions=$(code --list-extensions 2>/dev/null)

    # Claude Code extension
    if echo "$extensions" | grep -q "anthropic.claude-code"; then
        write_status "Claude Code extension already installed" "OK"
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would run: code --install-extension anthropic.claude-code"
    else
        code --install-extension anthropic.claude-code --force 2>/dev/null
        write_status "Claude Code extension installed" "OK"
    fi

    # Foam extension
    if echo "$extensions" | grep -q "foam.foam-vscode"; then
        write_status "Foam extension already installed" "OK"
    elif [ "$DRY_RUN" = true ]; then
        write_dry_run "Would run: code --install-extension foam.foam-vscode"
    else
        code --install-extension foam.foam-vscode --force 2>/dev/null
        write_status "Foam extension installed" "OK"
    fi

    INSTALLED+=("VS Code Extensions")
    echo ""
}

# ============================================================================
# SECTION 5: MAIN FLOW
# ============================================================================

# ── Phase 0: Welcome ──

write_banner

if [ "$DRY_RUN" = true ]; then
    echo -e "${BOLD}  [DRY RUN MODE]${RESET} ${DIM}No changes will be made. Showing what would happen.${RESET}"
    echo ""
fi

echo -e "${SAND}  5 minutes. 10 tools. Then you build.${RESET}"
echo -e "${DIM}  No code required. Seriously.${RESET}"
echo ""
echo -e "${CREAM}  What we're setting up:${RESET}"
echo ""
echo -e "${DIM}    REQUIRED                            ESSENTIAL${RESET}"
echo -e "    ${LIME}1. Git          ${DIM}track everything    ${LIME}5. Python     ${DIM}automate anything${RESET}"
echo -e "    ${LIME}2. Node.js      ${DIM}powers Claude       ${LIME}6. uv         ${DIM}fast installs${RESET}"
echo -e "    ${LIME}3. VS Code      ${DIM}your workspace      ${LIME}7. GitHub CLI ${DIM}ship & share${RESET}"
echo -e "    ${LIME}4. Claude Code  ${DIM}your AI builder${RESET}"
echo ""
echo -e "${DIM}    Plus: git identity, VS Code extensions${RESET}"
echo ""

if [ "$QUIET" != true ]; then
    read -p "  Ready? [Y/n] " response </dev/tty
    if [ "$response" = "n" ] || [ "$response" = "N" ]; then
        echo ""
        echo -e "${SAND}  No worries. Run this again when you're ready to build.${RESET}"
        echo ""
        exit 0
    fi
fi

# ── macOS: Ensure Homebrew ──

if [[ "$OS" == "macos" ]]; then
    ensure_homebrew

    # Ensure Xcode Command Line Tools are installed (prevents blocking GUI dialogs)
    if ! xcode-select -p &>/dev/null; then
        write_status "Installing Xcode Command Line Tools..." "INSTALL"
        xcode-select --install 2>/dev/null || true
        # Wait for CLT installation to complete
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
        write_status "Xcode Command Line Tools installed" "OK"
    fi
fi

# ── Phase 1: REQUIRED ──

write_phase "REQUIRED"

install_git
install_node
install_vscode
install_claude

# ── Phase 2: ESSENTIAL ──

write_phase "ESSENTIAL"

install_python
install_uv
install_gh

# ── Phase 3: CONFIGURE ──

write_phase "CONFIGURE"

set_git_identity
ensure_shell_path
install_extensions

# ── Summary ──

echo ""
echo -e "${DIM}  ---------------------------------------------------------${RESET}"
echo ""

if [ ${#FAILED[@]} -eq 0 ]; then
    echo -e "${SAGE}${BOLD}  +-------------------------------------------------------+${RESET}"
    echo -e "${SAGE}${BOLD}  |                                                       |${RESET}"
    echo -e "${SAGE}${BOLD}  |            ${RESET}${CREAM}${BOLD}You're ready to build.${RESET}${SAGE}${BOLD}                    |${RESET}"
    echo -e "${SAGE}${BOLD}  |                                                       |${RESET}"
    echo -e "${SAGE}${BOLD}  +-------------------------------------------------------+${RESET}"
else
    echo -e "${GOLD}${BOLD}  +-------------------------------------------------------+${RESET}"
    echo -e "${GOLD}${BOLD}  |                                                       |${RESET}"
    echo -e "${LIME}${BOLD}  |              ${RESET}${CREAM}${BOLD}Almost there.${RESET}${LIME}${BOLD}                          |${RESET}"
    echo -e "${GOLD}${BOLD}  |                                                       |${RESET}"
    echo -e "${GOLD}${BOLD}  +-------------------------------------------------------+${RESET}"
fi

echo ""
echo -e "${CREAM}  Installed:${RESET}"
for item in "${INSTALLED[@]}"; do
    echo -e "    ${SAGE}${CHECK}${RESET} ${SAND}${item}${RESET}"
done

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo ""
    echo -e "${GOLD}  Skipped (optional):${RESET}"
    for item in "${SKIPPED[@]}"; do
        echo -e "    ${DIM}- ${item}${RESET}"
    done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo -e "${CORAL}  Failed:${RESET}"
    for item in "${FAILED[@]}"; do
        echo -e "    ${CORAL}${CROSS}${RESET} ${item}"
    done
fi

echo ""
echo -e "${DIM}  ---------------------------------------------------------${RESET}"
echo ""
echo -e "${CREAM}  What happens next:${RESET}"
echo -e "${SAND}    1. Open a new terminal window${RESET}"
echo -e "${SAND}    2. Type ${LIME}claude${SAND} and start building${RESET}"
echo ""

if [ "$QUIET" != true ]; then
    read -p "  Press ENTER to open VS Code " </dev/tty
    if command -v code &>/dev/null; then
        code &
    fi
    echo ""
    echo -e "${CYAN}  VS Code is opening. Enjoy!${RESET}"
else
    echo -e "${CYAN}  Open VS Code and type 'claude' in the terminal to begin.${RESET}"
fi

echo ""
