# Claude Code Skills for Kuetix WSL

[Claude Code](https://claude.ai/code) skills that teach Claude the WSL (Workflow Specific Language) — so it can write, debug, and explain workflows for the [Kuetix Engine](https://github.com/kuetix/engine).

## Install

### One-liner (into current project)

```bash
curl -fsSL https://raw.githubusercontent.com/kuetix/wsl-skills/main/install.sh | bash
```

### Into a specific project

```bash
curl -fsSL https://raw.githubusercontent.com/kuetix/wsl-skills/main/install.sh | bash -s -- /path/to/project/.claude/skills
```

### Global (all projects)

```bash
curl -fsSL https://raw.githubusercontent.com/kuetix/wsl-skills/main/install.sh | bash -s -- ~/.claude/skills
```

### Manual

Copy the `.md` files from the `skills/` directory into your project's `.claude/skills/` folder.

## Skills

| Skill | Description |
|-------|-------------|
| [write-wsl](skills/write-wsl.md) | Write workflows in WSL (verbose state machine syntax) |
| [write-swsl](skills/write-swsl.md) | Write workflows in SWSL (simplified chaining syntax) |
| [write-service-transition](skills/write-service-transition.md) | Create Go service transitions (action handlers) |
| [explain-wsl](skills/explain-wsl.md) | Analyze and explain what a workflow does |
| [debug-wsl](skills/debug-wsl.md) | Debug parsing errors and runtime issues |
| [write-parser-test](skills/write-parser-test.md) | Write tests for the WSL parser |
| [convert-wsl-swsl](skills/convert-wsl-swsl.md) | Convert between WSL and SWSL syntax |

## Usage

Once installed, open your project with Claude Code and ask:

- "Write a workflow that validates user input and sends a notification"
- "Convert this WSL file to simplified syntax"
- "Explain what this workflow does"
- "Create a new service transition for payments"
- "Debug this parse error"

Claude automatically picks up the skills from `.claude/skills/` — no configuration needed.

## Requirements

- [Claude Code](https://claude.ai/code) CLI, desktop app, or IDE extension
- [Kuetix Engine](https://github.com/kuetix/engine) (`go get github.com/kuetix/engine`)