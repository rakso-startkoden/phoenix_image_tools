# Phoenix Image Tools - Development Guide

## Commands
- `mix deps.get` - Install dependencies
- `mix test` - Run all tests (includes lint checks)
- `mix test test/path/to/test_file.exs:line_number` - Run a specific test
- `mix lint` - Run formatter and Credo checks
- `mix format` - Format code
- `mix credo --strict` - Run static code analysis
- `mix dialyzer` - Run type checking

## Code Style Guidelines
- Line length: 98 characters max
- Indentation: 2 spaces
- Follow Phoenix/LiveView coding conventions
- Modules: PascalCase (e.g., `PhoenixImageTools.Storage.S3`)
- Functions: snake_case (e.g., `get_width_from_size`)
- Constants: module attributes with ALL_CAPS (e.g., `@EXTENSION_WHITELIST`)
- Documentation: All public functions must have @doc with examples
- Types: Use @spec for function signatures
- Errors: Return {:ok, result} or {:error, reason} tuples
- Exceptions: Use ! suffix for functions that may raise errors
- Configuration: Use Application.get_env with sensible defaults
- Testing: Include examples in documentation and separate test files
- Always run formatter and credo before committing