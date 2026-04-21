#!/bin/bash
# Install Kuetix WSL skills for Claude Code
# Usage: curl -fsSL https://raw.githubusercontent.com/kuetix/wsl-skills/main/install.sh | bash
#
# Optional argument: target skills directory (default: .claude/skills)
# Examples:
#   curl ... | bash                                    # into ./.claude/skills
#   curl ... | bash -s -- ~/.claude/skills             # global install
#   curl ... | bash -s -- /path/to/proj/.claude/skills # specific project

set -e

REPO="kuetix/wsl-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/skills"
TARGET="${1:-.claude/skills}"

SKILLS=(
  "convert-wsl-swsl"
  "debug-wsl"
  "explain-wsl"
  "write-module-transition"
  "write-parser-test"
  "write-service-transition"
  "write-swsl"
  "write-wsl"
)

mkdir -p "$TARGET"

echo "Installing Kuetix WSL skills to ${TARGET}/"
for name in "${SKILLS[@]}"; do
  echo "  -> ${name}"
  mkdir -p "${TARGET}/${name}"
  curl -fsSL "${BASE_URL}/${name}.md" -o "${TARGET}/${name}/SKILL.md"
done

echo ""
echo "Done! ${#SKILLS[@]} skills installed."
echo "Restart Claude Code to pick them up."
