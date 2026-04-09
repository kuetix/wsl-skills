# Skill: Write Module Transition

Create a module with transitions (service actions) for the kuetix/engine workflow system.

## When to use
When the user asks to create a new module, service module, transition module, or action handler that workflows can call via WSL/SWSL.

## Module Structure

Modules live under the `modules/` directory. Each module contains a `transitions/` package with Go structs that implement `interfaces.ServiceTransitions`.

### Directory Layout
```
modules/
└── <service>/
    └── <namespace>/
        └── transitions/
            └── <transition_name>.go
```

**Example:** A payment module at `modules/billing/payment/transitions/payment.go` maps to WSL action path `billing/payment/payment.Method()`.

### Path Mapping (WSL to Go)

```
WSL:  action billing/payment/payment.ChargeCard(amount: 100)
                ─────────────────── ──────────
                service path         method name
                │
                └── modules/billing/payment/transitions/payment.go
                    struct method: ChargeCard(amount interface{}) (r domain.FlowStepResult)
```

The mapping:
- **WSL import:** `import billing/payment`
- **WSL action:** `billing/payment/payment.ChargeCard(...)`
- **Go file:** `modules/billing/payment/transitions/payment.go`
- **DI key:** `transition/billing/payment/payment`

## Writing a Transition

### Basic Transition

```go
package transitions

import (
	"github.com/kuetix/engine/pkg/domain"
	"github.com/kuetix/engine/pkg/domain/interfaces"
	"github.com/kuetix/engine/pkg/workflow"
)

// paymentTransitions handles payment operations.
type paymentTransitions struct {
	workflow.BaseServiceTransition
}

// NewPaymentTransitions creates a new instance.
// The constructor MUST return interfaces.ServiceTransitions.
func NewPaymentTransitions() interfaces.ServiceTransitions {
	return &paymentTransitions{}
}

// ChargeCard charges a credit card.
// WSL: billing/payment/payment.ChargeCard(amount: 100, currency: "USD")
func (t *paymentTransitions) ChargeCard(amount interface{}, currency string) (r domain.FlowStepResult) {
	// Business logic here

	r.Success = true
	r.StatusCode = 200
	r.Response = map[string]interface{}{
		"id":       "txn_123",
		"amount":   amount,
		"currency": currency,
		"status":   "charged",
	}
	return
}
```

### Key Rules

1. **Package must be `transitions`** — always `package transitions`
2. **Embed `workflow.BaseServiceTransition`** — gives access to session context, response helpers, error handling
3. **Constructor returns `interfaces.ServiceTransitions`** — the code generator detects this to wire DI
4. **Struct name convention:** `<name>Transitions` in camelCase (e.g., `paymentTransitions`, `userServiceTransitions`)
5. **Constructor convention:** `New<Name>Transitions` in PascalCase (e.g., `NewPaymentTransitions`)
6. **Methods must be exported** (PascalCase) — they map to WSL action names

### Return Type: `domain.FlowStepResult`

```go
type FlowStepResult struct {
    Success    bool          // true = on success transition, false = on error transition
    Next       string        // optional: override next state name
    Error      error         // error details (set when Success = false)
    Response   interface{}   // result accessible via $alias.field in WSL
    StatusCode int           // HTTP-style status code
}
```

The `Response` field is what downstream states access via `$alias.field`:
```go
r.Response = map[string]interface{}{
    "id":     "user_123",
    "email":  "user@example.com",
}
// WSL: $Result.id => "user_123", $Result.email => "user@example.com"
```

### Method Parameter Types

WSL named parameters map to Go method arguments **by name** (not position). The engine uses `FunctionMetadata` to match WSL param names to Go arg names.

**Supported Go types:**
| Go Type | WSL Value |
|---------|-----------|
| `string` | `"hello"` |
| `int`, `int64` | `42` |
| `float64` | `3.14` |
| `bool` | `true`, `false` |
| `interface{}` | any value (string, number, object, array) |
| `map[string]interface{}` | `{key: "value"}` |
| `[]interface{}` | `["a", "b"]` |

**Parameter name must match WSL argument name:**
```go
// WSL: payment.Charge(amount: 100, currency: "USD")
func (t *paymentTransitions) Charge(amount interface{}, currency string) (r domain.FlowStepResult) {
    // 'amount' matches WSL param 'amount', 'currency' matches 'currency'
}
```

### Accessing Session Context

The `BaseServiceTransition` provides context access:

```go
func (t *paymentTransitions) ProcessOrder(orderId string) (r domain.FlowStepResult) {
    // Access workflow session context
    ctx := t.S() // shorthand for refreshed session context

    // Get a value from context
    userId := t.GetValue("userId")

    // Set a value in context (accessible by downstream states)
    t.SetValue("processedAt", time.Now().String())

    // Get a flow property/option
    timeout := t.Property("timeout")

    // Set response directly on worker (alternative to FlowStepResult)
    t.SetResponse(map[string]interface{}{"status": "ok"}, 200)

    // Set error on worker
    t.SetError(&issues.Issue{Message: "not found"}, 404)

    // Create and set a simple error
    t.NewIssue("something went wrong", 500)

    r.Success = true
    r.Response = map[string]interface{}{"orderId": orderId}
    return
}
```

### Special Parameter: WorkerSessionContext

A method can receive the full session context by naming a parameter `p` with type `*workflow.WorkerSessionContext`:

```go
func (t *paymentTransitions) ComplexAction(p *workflow.WorkerSessionContext, amount float64) (r domain.FlowStepResult) {
    // p gives direct access to the full execution context
    // flow, worker, parser, engine, etc.
    flow := p.Flow
    worker := p.Worker

    r.Success = true
    return
}
```

### Error Handling in Transitions

```go
func (t *paymentTransitions) ValidateCard(cardNumber string) (r domain.FlowStepResult) {
    if len(cardNumber) < 13 {
        r.Success = false
        r.StatusCode = 400
        r.Error = fmt.Errorf("invalid card number")
        r.Response = map[string]interface{}{
            "message": "Card number too short",
            "code":    "INVALID_CARD",
        }
        return
    }

    r.Success = true
    r.StatusCode = 200
    r.Response = map[string]interface{}{
        "valid":  true,
        "last4":  cardNumber[len(cardNumber)-4:],
    }
    return
}
```

When `r.Success = false`, the engine follows `on error ->` transitions in WSL.

## Code Generation & DI Registration

The engine uses `kue` CLI to auto-generate two files:

### `modules/meta.go` (generated)
Contains `FunctionMetadata` for all transition methods — maps arg names, types, counts:
```go
boot.AddMetaFunctionCache(map[string]map[string]map[string]interfaces.FunctionMetadata{
    "billing/payment": {
        "payment": {
            "ChargeCard": {
                Name: "ChargeCard",
                NumIn: 2, NumOut: 1,
                ArgTypes: []string{"interface{}", "string"},
                ArgNames: []string{"amount", "currency"},
                ReturnTypes: []string{"domain.FlowStepResult"},
                ReturnNames: []string{"r"},
            },
        },
    },
})
```

### `modules/di.go` (generated)
Registers transitions in the DI container:
```go
di.DependencyInjection["billing/payment"] = func(name string) {
    di.ToResolve(defines.TransitionPrefix+"billing/payment"+"/"+"payment",
        func() interface{} {
            return workflow.ServiceTransitionMapping{
                ServiceName: name,
                Name: "payment",
                Impl: transitionsBillingPayment.NewPaymentTransitions(),
            }
        })
}
```

**You don't write these files manually** — run `kue` CLI to regenerate after adding transitions.

## Complete Example: User Authentication Module

### Directory
```
modules/
└── auth/
    └── login/
        └── transitions/
            └── login.go
```

### Go Code (`modules/auth/login/transitions/login.go`)
```go
package transitions

import (
	"fmt"

	"github.com/kuetix/engine/pkg/domain"
	"github.com/kuetix/engine/pkg/domain/interfaces"
	"github.com/kuetix/engine/pkg/workflow"
)

type loginTransitions struct {
	workflow.BaseServiceTransition
}

func NewLoginTransitions() interfaces.ServiceTransitions {
	return &loginTransitions{}
}

// CheckPassword verifies user credentials.
func (t *loginTransitions) CheckPassword(request interface{}, user interface{}) (r domain.FlowStepResult) {
	req := request.(map[string]interface{})
	usr := user.(map[string]interface{})

	if req["password"] != usr["passwordHash"] {
		r.Success = false
		r.StatusCode = 401
		r.Error = fmt.Errorf("invalid credentials")
		return
	}

	r.Success = true
	r.StatusCode = 200
	r.Response = map[string]interface{}{
		"authenticated": true,
		"userId":        usr["id"],
	}
	return
}

// GenerateToken creates an auth token.
func (t *loginTransitions) GenerateToken(user interface{}) (r domain.FlowStepResult) {
	usr := user.(map[string]interface{})

	r.Success = true
	r.StatusCode = 200
	r.Response = map[string]interface{}{
		"accessToken":  "jwt_" + usr["id"].(string),
		"refreshToken": "refresh_" + usr["id"].(string),
		"expiresIn":    3600,
	}
	return
}
```

### Corresponding WSL
```wsl
module auth.login
import auth/login

workflow user_login {
  start: CheckPassword

  state CheckPassword(Request, User) {
    action auth/login/login.CheckPassword(request: $Request, user: $User)
    on success -> GenerateToken(User)
    on error -> InvalidCredentials
  }

  state GenerateToken(User) {
    action auth/login/login.GenerateToken(user: $User) as Token
    end ok
  }

  state InvalidCredentials {
    action services/common/response.ResponseError(message: "Invalid credentials", code: 401)
    end error
  }
}
```

## Guidelines

- One transition file per domain concern (e.g., `payment.go`, `refund.go`, `subscription.go`)
- Keep methods focused — one action per method
- Always return `domain.FlowStepResult`, set `Success`, `StatusCode`, and `Response`
- Use `BaseServiceTransition` helpers (`S()`, `GetValue()`, `SetValue()`, `SetError()`) for context access
- Parameter names in Go must match WSL argument names exactly
- Constructor must return `interfaces.ServiceTransitions` — this is how the code generator detects it
- Run `kue update` after adding/modifying transitions to regenerate `meta.go`, `di.go`, and `modules.json`

## kue CLI Commands for Module Transitions

### Scaffold a new module
```bash
kue add module <name>
# or
kue generate module <name>
```
Generates: `modules/services/<name>/transitions/<name>.go`

### Update module cache (after editing transitions)
```bash
kue update              # regenerate modules/di.go, modules/meta.go, modules.json
kue update --verbose    # with detailed output
kue update --quiet      # silent mode
```
**Always run `kue update` after:**
- Adding a new transition file
- Adding/removing/renaming methods on a transition struct
- Changing method signatures (parameters, return types)

### Install a third-party module package
```bash
kue package install <package-name>
```
Downloads and installs a reusable kuetix package (with its modules, workflows, transitions) into your project.

### Enable an installed module
```bash
kue enable <module-name>
```
Updates `modules/modules.go` to import and activate the module. This registers the module's transitions in the DI container so workflows can call them.

### Full workflow: add a module from scratch
```bash
# 1. Scaffold the transition
kue add module payment

# 2. Edit the generated file — add your methods
#    modules/services/payment/transitions/payment.go

# 3. Regenerate DI and metadata cache
kue update

# 4. Write a workflow that uses it
#    workflows/common/payment.wsl

# 5. Run it
kue run workflows/common/payment.wsl
```

### Full workflow: install a third-party package
```bash
# 1. Install the package
kue package install billing/payment

# 2. Enable it in your project
kue enable billing/payment

# 3. Update the module cache
kue update

# 4. Use its transitions in your workflows
#    action billing/payment/payment.ChargeCard(amount: 100)
```