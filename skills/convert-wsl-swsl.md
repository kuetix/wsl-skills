# Skill: Convert Between WSL and SWSL

Convert workflows between WSL (verbose) and SWSL (simplified) syntax.

## When to use
When the user asks to convert a `.wsl` file to `.swsl` or vice versa.

## WSL to SWSL Conversion Rules

### Linear workflows convert directly
WSL:
```wsl
module example
import services/common

workflow my_flow {
  start: Step1

  state Step1 {
    action services/common/action.Do(value: "hello") as Result
    on success -> Step2(Result)
  }

  state Step2(Result) {
    action services/common/response.ResponseValue(value: $Result.data)
    end ok
  }
}
```

SWSL:
```swsl
module example
import services/common

services/common/action.Do(value: "hello") as Result ->
services/common/response.ResponseValue(value: $Result.data) -> .
```

### Error transitions become `def` + `<-`
WSL with error handling:
```wsl
state Process {
    action service/path.Method(value: "x") as Result
    on success -> Next
    on error -> HandleError
}

state HandleError {
    action services/common/errors.OnAnyError(msg: "failed")
    end fail
}
```

SWSL:
```swsl
def services/common/errors.OnAnyError(msg: "failed") as errorHandler -> .

service/path.Method(value: "x") as Result <- errorHandler ->
```

### Feature/Solution orchestration
WSL:
```wsl
feature my_feature {
  start: RunWorkflow
  state RunWorkflow {
    action workflow my_workflow
    on success -> Done
  }
  state Done {
    end ok
  }
}
```

SWSL:
```swsl
feature my_feature
workflow:my_workflow() -> .
```

### Constants and imports transfer directly
Both syntaxes use identical `const {}` and `import` blocks.

## SWSL to WSL Conversion Rules

### Chain becomes explicit states
SWSL:
```swsl
action1(params) as r1 ->
action2(params) as r2 ->
action3(params) -> .
```

WSL (generate state names from action or alias):
```wsl
workflow <name> {
  start: State_r1

  state State_r1 {
    action action1(params) as r1
    on success -> State_r2
  }

  state State_r2 {
    action action2(params) as r2
    on success -> State_Final
  }

  state State_Final {
    action action3(params)
    end ok
  }
}
```

### `def` + `<-` becomes error states
SWSL `def` handlers expand to dedicated error states in WSL.

## Limitations
- **WSL with complex branching (`when` expressions, multiple `on success` paths) cannot be fully expressed in SWSL** — SWSL is linear. Warn the user if the WSL has non-linear control flow.
- **State attributes** (`if`, `continue on fail`, `skip to`) have no SWSL equivalent.
- SWSL implicitly names states — when converting to WSL, generate meaningful names from aliases or action methods.