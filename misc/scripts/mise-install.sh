#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Install mise (formerly rtx) - a tool version manager
# This script installs mise if it's not already installed

set -e

if command -v mise &> /dev/null; then
    echo "mise is already installed"
    mise --version
else
    echo "Installing mise..."
    curl https://mise.run | sh
    
    # Add mise to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    # Add to shell profile if not already there
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    
    echo "mise installed successfully!"
    echo "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
fi
