#!/bin/bash
# Install Kuetix WSL skills for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/kuetix/wsl-skills/main/install.sh | bash

set -e

REPO="kuetix/wsl-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/skills"
TARGET="${1:-.claude/skills/wsl}"

SKILLS=(
  "convert-wsl-swsl.md"
  "debug-wsl.md"
  "explain-wsl.md"
  "write-module-transition.md"
  "write-parser-test.md"
  "write-service-transition.md"
  "write-swsl.md"
  "write-wsl.md"
)""

mkdir -p "$TARGET"

echo "Installing Kuetix WSL skills to ${TARGET}/"
for skill in "${SKILLS[@]}"; do
  echo "  -> ${skill}"
  curl -fsSL "${BASE_URL}/${skill}" -o "${TARGET}/${skill}"
done

echo ""
echo "Done! ${#SKILLS[@]} skills installed."
echo "Open your project with Claude Code to start using them."
