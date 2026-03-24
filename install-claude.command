#!/bin/bash
# ============================================================================
# CLAUDE CODE INSTALLER (macOS)
# Download this file and double-click to install everything you need.
#
# What happens:
#   1. Opens Terminal
#   2. Downloads the installer script
#   3. Installs Git, Node.js, VS Code, Claude Code, uv, GitHub CLI
#   4. Configures your environment
#   5. Opens VS Code when done
#
# macOS may warn you - right-click the file, select "Open", then "Open" again
# ============================================================================

echo ""
echo "  ============================================="
echo "    Claude Code Installer"
echo "    Setting up your development environment..."
echo "  ============================================="
echo ""

curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash

echo ""
echo "  ============================================="
echo "    Installation complete."
echo "    You can close this window."
echo "  ============================================="
echo ""
read -p "  Press ENTER to close"
