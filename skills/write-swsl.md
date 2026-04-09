# Skill: Write SimplifiedWSL Workflows

Write workflows in SWSL (Simplified Workflow Specific Language) for the kuetix/engine.

## When to use
When the user asks to create, write, or generate a `.swsl` workflow file, or asks for a "simplified" workflow.

## SWSL Syntax Reference

SWSL is a concise alternative to WSL with implicit state chaining. Instead of explicit state machines, actions are chained with `->` and errors are bound with `<-`.

### File Structure
```swsl
module <name>          // optional — derived from filename if omitted

<type> <name>          // optional flow type declaration: workflow, feature, solution

import <service_path>

const {
    key: "value"
}

// Define error handlers
def <service/path.Method>(params) as <handler_name> -> .

// Action chain
<service/path.Method>(params) as <alias> <- <handler> ->
<service/path.Method>(params) as <alias> -> .
```

### Flow Types
- Default is `workflow` if omitted
- Declare explicitly: `feature payment_processing` or `solution complete_app`

### Action Chaining with `->`
Actions chain left-to-right. Each `->` creates an implicit success transition:
```swsl
action1(params) as result1 ->
action2(params) as result2 ->
action3(params) -> .
```
The `.` terminal marker ends the workflow (equivalent to `end ok`).

### Error Handlers with `def` and `<-`
Define handlers with `def`, bind them to actions with `<-`:
```swsl
// Define: handler that runs on error, then terminates
def services/common/errors.OnAnyError(msg: "error") as errorHandler -> .

// Define: handler that chains to another action before terminating
def services/common/errors.LogError(level: "error") as logError ->
    services/common/notification.Send(to: "admin") -> .

// Bind: action uses errorHandler on failure
service/path.Method(params) as result <- errorHandler -> nextAction(params) -> .
```

### Variable References
- `$constants.key` — from const block (deep nesting: `$constants.config.limits.max`)
- `$alias.field` — from prior action result
- `$error.message` — from error context

### Nested Structures in Arguments
```swsl
billing/payment.ValidateCard(
    amount: 500,
    card: {
        number: "4111111111111111",
        expiry: { month: 12, year: 2025 }
    },
    tags: ["online", "card"]
) as validation <- errorHandler ->
```

### Calling Sub-Flows (features/solutions)
```swsl
solution complete_payment

// Call a feature
feature:feature_payment() <- criticalError ->

// Call a workflow
workflow:workflow_validate() <- errorHandler ->

// With parameters
workflow:workflow_process(retries: 3) <- errorHandler ->
```

### Comments
```swsl
// Single line comment
```

### Complete Example
```swsl
import services/common

const {
    msg: "Hello World",
    code: 200
}

def services/common/errors.OnAnyError(msg: "error", statusCode: 400) as errorHandler ->
    services/common/response.ResponseValue(value: $error.message, statusCode: 500) -> .

converse/speak.Say(on: "message", v: $constants.msg) as response <- errorHandler ->
    services/common/response.ResponseValue(value: $response.message, statusCode: $constants.code) -> .
```

### Solution Example (orchestrating features)
```swsl
module payment_flow

solution complete_payment

const {
    environment: "production"
}

def errors.HandleCriticalError(severity: "critical") as criticalError -> .

context.Set(key: "payment_amount", value: 100.00) ->
context.Set(key: "payment_method", value: "credit_card") ->
feature:feature_payment() <- criticalError ->
feature:feature_notification() <- criticalError ->
services/common.Response(message: "Done", status: "success") -> .
```

## Guidelines
- Place workflow files in `runtime/workflows/<workflow_name>/` directory
- Prefer SWSL over WSL for simple linear flows — it's more concise
- Use WSL when you need complex conditional branching (`when` expressions) or non-linear state machines
- Module name is optional — derived from filename if omitted
- Always end chains with `-> .` (terminal)
- Define error handlers before using them
- Use `as alias` to capture results for downstream reference
- Pipes for type coercion: `$value|int`, `$value|toArray`