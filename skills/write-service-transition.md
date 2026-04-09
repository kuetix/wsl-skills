# Skill: Write Service Transition

Create a Go service transition (action handler) for the kuetix/engine workflow system.

## When to use
When the user asks to create a new service, action handler, or transition function that workflows can call.

## Architecture

Workflows call service methods via reflection. A service is a Go struct that implements `ServiceTransitions` (marker interface) and is registered in the DI container with a `TransitionPrefix`.

### Service Structure
```go
package myservice

import (
    "github.com/kuetix/engine/pkg/domain"
)

// MyService handles <description>.
type MyService struct {
    // Inject dependencies via constructor
}

// NewMyService creates a new MyService instance.
func NewMyService() *MyService {
    return &MyService{}
}
```

### Method Signatures

Action methods are invoked via reflection. The engine uses `FunctionMetadata` to map WSL named parameters to Go function arguments.

**Input patterns:**
- Named parameters from WSL map to Go function args by position
- Supported types: `string`, `int`, `int64`, `float64`, `bool`, `interface{}`, `map[string]interface{}`, `[]interface{}`

**Return patterns:**
- `(interface{}, error)` — most common, returns result and optional error
- `(map[string]interface{}, error)` — structured result
- `error` — action with no return value

### Example Service
```go
package response

import (
    "fmt"
)

type ResponseService struct{}

func NewResponseService() *ResponseService {
    return &ResponseService{}
}

// ResponseValue returns a simple value response.
// WSL: services/common/response.ResponseValue(value: "hello", statusCode: 200)
func (s *ResponseService) ResponseValue(value interface{}, statusCode int) (map[string]interface{}, error) {
    return map[string]interface{}{
        "value":      value,
        "statusCode": statusCode,
    }, nil
}
```

### Registration (DI Container)

Services are registered in the boot/dependency injection phase:
```go
container.Bind("services/common/response", func() *response.ResponseService {
    return response.NewResponseService()
})
```

The container path maps to the WSL import + action path:
- WSL: `import services/common` + `action services/common/response.ResponseValue(...)`
- Container key: `services/common/response`
- Method: `ResponseValue`

### WSL-to-Go Mapping

Given WSL action:
```wsl
action billing/payment.ChargeCard(amount: 100, currency: "USD", accountId: $balance.id) as charge
```

The engine:
1. Resolves `billing/payment` from DI container
2. Finds method `ChargeCard` via reflection
3. Maps named params to positional args using `FunctionMetadata`
4. Calls `ChargeCard(100, "USD", "<resolved_id>")`
5. Stores result in context as `charge`

### Error Handling Service Example
```go
package errors

type ErrorService struct{}

func NewErrorService() *ErrorService {
    return &ErrorService{}
}

// OnAnyError is a generic error handler.
// WSL: def services/common/errors.OnAnyError(msg: "error") as errorHandler -> .
func (s *ErrorService) OnAnyError(msg string, statusCode int) (map[string]interface{}, error) {
    return map[string]interface{}{
        "message":    msg,
        "statusCode": statusCode,
    }, nil
}
```

## Guidelines
- Keep service methods focused — one action per method
- Return `map[string]interface{}` for results that downstream states will access via `$alias.field`
- Use `interface{}` for params that accept variable types (strings, objects, arrays from WSL)
- Method names are PascalCase and map directly to the WSL action name
- Service paths use forward slashes matching the import structure
- Always return errors rather than panicking