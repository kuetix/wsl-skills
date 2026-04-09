# Skill: Write WSL Parser Test

Create tests for the WSL/SWSL parser in the `internal/wsl` package.

## When to use
When the user asks to write tests for WSL parsing, add test cases for new syntax, or verify parser behavior.

## Test Patterns

### Regular WSL Parse Test
```go
func TestMyFeature(t *testing.T) {
    src := `
module test

import services/common

const {
    key: "value"
}

workflow test_workflow {
  start: Init

  state Init {
    action services/common/response.ResponseValue(value: $constants.key) as Result
    on success -> Done
  }

  state Done {
    end ok
  }
}
`
    ast, graphs, err := ParseAll(src, "test")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }

    // Verify module
    if ast.Name != "test" {
        t.Errorf("expected module name 'test', got %q", ast.Name)
    }

    // Verify workflows
    if len(ast.Workflows) != 1 {
        t.Fatalf("expected 1 workflow, got %d", len(ast.Workflows))
    }

    wf := ast.Workflows[0]
    if wf.Name != "test_workflow" {
        t.Errorf("expected workflow name 'test_workflow', got %q", wf.Name)
    }

    // Verify states
    if len(wf.States) != 2 {
        t.Fatalf("expected 2 states, got %d", len(wf.States))
    }

    // Verify graphs
    g, ok := graphs["test_workflow"]
    if !ok {
        t.Fatal("expected graph for 'test_workflow'")
    }
    if g.Start != "Init" {
        t.Errorf("expected start 'Init', got %q", g.Start)
    }
}
```

### SimplifiedWSL Parse Test
```go
func TestSimplifiedMyFeature(t *testing.T) {
    src := `
import services/common

const {
    msg: "test"
}

def services/common/errors.OnAnyError() as errorHandler -> .

services/common/action.Do(value: $constants.msg) as result <- errorHandler ->
services/common/response.ResponseValue(value: $result.data) -> .
`
    ast, graphs, err := ParseAllSimplified(src, "test_simplified")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }

    if ast.Name != "test_simplified" {
        t.Errorf("expected module 'test_simplified', got %q", ast.Name)
    }

    if len(ast.Workflows) != 1 {
        t.Fatalf("expected 1 workflow, got %d", len(ast.Workflows))
    }
}
```

### Error Case Test
```go
func TestDuplicateStateError(t *testing.T) {
    src := `
module test

workflow test_wf {
  start: Init

  state Init {
    action svc/test.Do()
    end ok
  }

  state Init {
    action svc/test.Do()
    end ok
  }
}
`
    _, _, err := ParseAll(src, "test")
    if err == nil {
        t.Fatal("expected error for duplicate state")
    }
}
```

### File-Based Test (loading from runtime/workflows)
```go
func TestParseExampleFile(t *testing.T) {
    content, err := os.ReadFile("../../runtime/workflows/wsl_hello_world/example.wsl")
    if err != nil {
        t.Fatalf("failed to read file: %v", err)
    }

    ast, graphs, err := ParseAll(string(content), "example")
    if err != nil {
        t.Fatalf("parse error: %v", err)
    }

    // Verify expected workflows exist
    names := make(map[string]bool)
    for _, wf := range ast.Workflows {
        names[wf.Name] = true
    }

    for _, expected := range []string{"example", "wsl_hello_world"} {
        if !names[expected] {
            t.Errorf("expected workflow %q not found", expected)
        }
    }
}
```

## Key AST Types to Assert On
- `ast.Name` — module name
- `ast.Imports` — `[]Import{Path string}`
- `ast.Constants` — `map[string]interface{}`
- `ast.Workflows` — `[]Workflow{Name, Type, StartState, States}`
- `wf.States` — `[]State{Name, Action, Transitions, Terminal, TerminalKind, Params}`
- `state.Action` — `Action{Service, Method, Args, Alias}`
- `state.Transitions` — `[]Transition{Condition, Target, WhenExpr, Args}`

## Key Graph Types to Assert On
- `graph.WorkflowName`, `graph.WorkflowType`
- `graph.Start` — start node name
- `graph.Nodes` — `map[string]*Node`
- `node.Action`, `node.Edges`, `node.Terminal`, `node.TerminalKind`
- `edge.Target`, `edge.Condition`, `edge.WhenExpr`

## Run Tests
```bash
go test ./internal/wsl/... -v
go test ./internal/wsl/... -v -run TestSpecificName
```
