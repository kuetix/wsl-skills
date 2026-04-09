# Skill: Write WSL Workflows

Write workflows in WSL (Workflow Specific Language) for the kuetix/engine.

## When to use
When the user asks to create, write, or generate a `.wsl` workflow file.

## WSL Syntax Reference

### File Structure
```wsl
module <module_name>

import <service_path>

const {
    key: "value",
    nested: {
        inner: "value"
    }
}

workflow <name> {
  start: <StartState>

  state <StateName> {
    action <service/path.Method>(param: value) as <Alias>
    on success -> <NextState>
  }

  state <FinalState> {
    action <service/path.Method>(param: value)
    end ok
  }
}
```

### Flow Types (hierarchical: solution > feature > workflow)
- `workflow` — atomic unit, executes actions via service calls
- `feature` — orchestrates multiple workflows
- `solution` — orchestrates features and workflows

### State Attributes
- `if <expression>` — conditional execution guard
- `continue on fail` — proceed even if action fails
- `skip to` — skip state under certain conditions
- Combined: `if` + `continue on fail` can coexist

### State Parameters
States can accept parameters from prior results:
```wsl
state ProcessResult(CheckResult) {
    action service/path.Method(data: $CheckResult.field)
    end ok
}
```

### Transitions
- `on success -> NextState` — transition on success
- `on success -> NextState(Alias)` — pass result alias
- `on success when <expr> -> State` — conditional transition
- `on error -> ErrorState` — transition on error
- `end ok` — terminal success state
- `end fail` / `end error` — terminal failure state

### When Expressions (conditional branching)
```wsl
on success when $constants.version == "1.0.0" -> VersionOneHandler
on success when $constants.maxRetries > 2 -> HighRetryPath
on success -> DefaultHandler
```

### Variable References
- `$constants.key` — from const block (supports deep nesting: `$constants.cfg.timeout`)
- `$Alias.field` — from prior action result (supports arrays: `$Alias.items[0].name`)
- `$ParamName` — from state parameters
- `$error.message` — from error context

### Action Arguments
- Named params: `action service/path.Method(key: "value", num: 42)`
- Object literals: `action service/path.Method(config: {timeout: 5000})`
- Array literals: `action service/path.Method(items: ["a", "b"])`
- Variable refs: `action service/path.Method(value: $constants.key)`
- Type coercion: `action service/path.Method(code: $value|int)`

### Orchestration (features/solutions calling sub-flows)
```wsl
feature my_feature {
  start: Step1
  state Step1 {
    action workflow basic_step
    on success -> Step2
  }
  state Step2 {
    action workflow process_data
    end ok
  }
}

solution my_solution {
  start: Init
  state Init {
    action feature my_feature
    on success -> Done
  }
  state Done {
    end ok
  }
}
```

### Comments
```wsl
// Single line comment
# Also a single line comment
```

### Constants
Auto-typed values: strings (`"hello"`), integers (`42`), floats (`3.14`), booleans (`true`/`false`), null.
Nested objects and arrays supported:
```wsl
const {
    headers: [
        { key: "Content-Type", value: "application/json" }
    ],
    config: {
        limits: {
            maxAmount: 10000,
            currencies: ["USD", "EUR"]
        }
    }
}
```

## Guidelines
- Place workflow files in `runtime/workflows/<workflow_name>/` directory
- Use descriptive state names in PascalCase
- Use `as Alias` to name action results for downstream access
- Always define a `start:` state
- Terminal states must have `end ok` or `end fail`
- Non-terminal states must have at least one `on success ->` transition
- Import only the service paths actually used
- Module name typically matches the directory/file name