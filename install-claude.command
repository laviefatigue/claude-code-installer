#!/bin/bash
# ============================================================================
# Replace University — Claude Code Installer (macOS)
# Thin shell: downloads and runs install.sh seamlessly.
# The branded experience lives in install.sh — this just delivers it.
#
# Double-click to run. macOS may warn — right-click → "Open" → "Open" again.
# ============================================================================

curl -fsSL https://raw.githubusercontent.com/laviefatigue/claude-code-installer/master/install.sh | bash

echo ""
read -p "  Press ENTER to close"
