# Changelog

## 0.1.0

Initial release.

### Features

- **OpenAPI 3.1** support with JSON Schema 2020-12 via json_schemer
- **RSpec adapter** with full DSL (`path`/`get`/`post`/`response`/`run_test!`)
- **Minitest adapter** with `api_path`/`assert_api_response` DSL
- **Schema components** as Ruby classes with inheritance, key transformation, and scoped loading
- **Runtime middleware** for deep request/response validation (parameter types, body schema, `$ref` resolution)
- **Strong params** derived from schema components (`permitted_params`, `openapi_permit` controller helper)
- **Spec generation** from test definitions (YAML/JSON output)
- **Rails engine** with specs controller, optional Swagger UI, and generators
- **Schema coverage** tracking
