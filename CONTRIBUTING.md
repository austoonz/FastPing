# Contributing to FastPing

Thank you for your interest in contributing to the FastPing PowerShell module!

## Prerequisites

- **PowerShell**: Version 5.1 or PowerShell 7.x
- **Git**: For version control

## Local Development

### Initial Setup

1. Clone the repository:
   ```powershell
   git clone https://github.com/austoonz/FastPing.git
   cd FastPing
   ```

2. Install PowerShell dependencies:
   ```powershell
   .\install_nuget.ps1
   .\install_modules.ps1
   ```

### Building the Module

```powershell
# Build the module
.\build.ps1 -Build

# Run tests
.\build.ps1 -Test

# Run code analysis
.\build.ps1 -Analyze

# Auto-format code
.\build.ps1 -Fix

# Full build pipeline (clean, analyze, test, build, package)
.\build.ps1 -Full
```

## Development Workflow

1. Create a feature branch
2. Make your changes
3. Run `.\build.ps1 -Full` to validate
4. Commit and push
5. Create a Pull Request

## Testing Guidelines

- **Minimum Coverage**: 80% code coverage
- **Test Framework**: Pester 5.3.0+
- **Test Location**: `src/Tests/Unit/`

## Code Style

- Follow PowerShell best practices
- Use single quotes for static strings
- Use double quotes for variable expansion
- Always use named parameters for clarity

## Getting Help

- **Issues**: Report bugs via [GitHub Issues](https://github.com/austoonz/FastPing/issues)
- **Documentation**: [Online documentation](https://austoonz.github.io/FastPing/)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
