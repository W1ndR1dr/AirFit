#!/usr/bin/env bash
# Setup script to install required development tools.
# This script requires internet access. Run on a machine with network connectivity.

set -e

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"
fi

# Install SwiftLint and SwiftFormat
brew install swiftlint swiftformat

echo "Development tools installed."

