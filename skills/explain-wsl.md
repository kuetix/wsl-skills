# Skill: Explain WSL/SWSL Workflow

Analyze and explain a WSL or SWSL workflow file.

## When to use
When the user asks to explain, analyze, review, or describe what a `.wsl` or `.swsl` workflow does.

## How to analyze

### For WSL (.wsl) files:
1. **Module & Imports** — What module is this? What services does it depend on?
2. **Constants** — What configuration values are defined?
3. **Flow type** — Is it a `workflow`, `feature`, or `solution`?
4. **State machine** — Trace the execution path from `start:` through all states
5. **Actions** — What service methods are called at each state?
6. **Data flow** — How do `as Alias` results flow between states via parameters?
7. **Branching** — Are there `when` expressions for conditional transitions?
8. **Error handling** — Are there `on error` transitions? `continue on fail`?
9. **Terminal states** — Where does it end (`end ok` / `end fail`)?

### For SWSL (.swsl) files:
1. **Module & Imports** — What module/flow type is declared?
2. **Constants** — What configuration values are defined?
3. **Error handlers** — What `def` handlers exist and what do they do?
4. **Action chain** — Trace the `->` chain from first action to terminal `.`
5. **Error bindings** — Which actions have `<-` error handler bindings?
6. **Sub-flow calls** — Any `workflow:`, `feature:` calls?
7. **Data flow** — How do `as alias` results feed into subsequent actions?

### Hierarchy awareness
- **Solutions** orchestrate features and workflows
- **Features** orchestrate workflows
- **Workflows** execute atomic service actions
- All levels share context via `WorkerSessionContext`

## Output format
Provide:
- A brief plain-English summary of what the workflow accomplishes
- The execution flow as a numbered sequence
- Key data dependencies between states
- Any potential issues or observations (unreachable states, missing error handling, etc.)