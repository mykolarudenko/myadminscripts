#!/bin/bash
# Installs GitHub CLI on Debian/Ubuntu systems.
set -e

echo "🔧 Checking for GitHub CLI (gh)..."
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI is already installed."
    exit 0
fi

echo "🚀 Installing GitHub CLI..."

# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install gh
sudo apt update
sudo apt install -y gh

echo "✅ GitHub CLI has been installed successfully."
echo "➡️  Next, run 'gh auth login' to authenticate with GitHub."
