# Skill: Debug WSL Parsing & Execution

Debug issues with WSL/SWSL workflow parsing or engine execution.

## When to use
When the user reports a parsing error, runtime error, or unexpected behavior in a workflow.

## Debugging Steps

### 1. Parse Errors
WSL parse errors include position info (line, column). Check:
- **Lexer errors** — Invalid tokens, unclosed strings, unexpected characters
- **Parser errors** — Missing keywords (`start:`, `state`, `action`), unclosed braces, missing `->` or `.`
- **Semantic errors** — Duplicate states, missing start state, transition to nonexistent state, `end` + `on success` conflict

Key files:
- `internal/wsl/lexer.go` — Token scanning
- `internal/wsl/parser.go` — CST construction (regular WSL)
- `internal/wsl/simplified_wsl.go` — SWSL parsing
- `internal/wsl/build_ast.go` — AST construction + semantic validation
- `internal/wsl/errors.go` — Error types

### 2. Runtime Errors
Check the execution pipeline:
- `pkg/workflow/engine.go` — Workflow loading and execution loop
- `pkg/workflow/worker.go` — State processing and context management
- `pkg/workflow/call_function.go` — Reflection-based service method invocation
- `pkg/workflow/workflow.go` — Flow schema and transition loading

Common runtime issues:
- **Service not found** — DI container missing binding for service path
- **Method not found** — Method name mismatch between WSL and Go service
- **Argument mismatch** — WSL params don't match Go method signature (count or types)
- **Variable resolution** — `$alias.field` references nonexistent result or field
- **Nil context** — Accessing context value that was never set

### 3. Testing Workflows
Run parser tests:
```bash
go test ./internal/wsl/... -v -run TestName
```

Run full test suite:
```bash
make test
```

Key test files:
- `internal/wsl/parser_test.go` — Regular WSL parsing
- `internal/wsl/simplified_wsl_test.go` — SWSL parsing
- `internal/wsl/build_ast_test.go` — AST construction
- `internal/wsl/const_test.go` — Constants parsing
- `internal/wsl/when_test.go` — When expression parsing
- `internal/wsl/example_file_test.go` — File-based integration tests

### 4. API Entry Points
The parsing pipeline has clean entry points in `internal/wsl/api.go`:
- `ParseAll(src, name)` — Full WSL pipeline: CST -> AST -> Graphs
- `ParseAllSimplified(src, name)` — Full SWSL pipeline: AST -> Graphs
- `ParseCST(src, name)` — WSL to CST only
- `BuildAST(cst)` — CST to AST with validation
- `BuildGraphs(ast)` — AST to IR graphs

### 5. Flow Validation
`pkg/workflow/workflow.go` contains `CorrectFlow()` which validates:
- State consistency
- Transition integrity
- Flow options and properties

## Tips
- Always read the exact error message — WSL errors include line:column
- For SWSL, remember that states are implicit — the parser generates state names
- Check that service import paths match DI container registration paths
- Variable references (`$constants.x`, `$alias.y`) are resolved at runtime, not parse time
