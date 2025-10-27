# GitHub Copilot Instructions for K.PSGallery.PackageRepoProvider

## Project Overview
This is an aggregator/facade module for private PowerShell package repositories. It provides a unified API for managing packages across different registry providers (GitHub Packages, GitLab Package Registry, etc.).

## Architecture Principles

### Provider Routing
- The module automatically detects provider types from registry URIs
- GitHub: Host contains `nuget.pkg.github.com`
- GitLab: Path contains `/packages/nuget/`
- Each provider implements standard interface functions (Invoke-RegisterRepo, Invoke-Publish, etc.)

### Module Structure
- **Public/**: Exported cmdlets with full comment-based help
- **Private/**: Internal helper functions
- **Tests/**: Pester tests for all functions

## Coding Standards

### PowerShell Best Practices
- Target PowerShell 7.0+
- Use approved verbs (Get, Set, New, Remove, Register, Publish, Install, Import)
- Include comprehensive comment-based help for all public functions
- Use proper parameter validation attributes
- Support common parameters like -Verbose, -ErrorAction

### Security
- Never log credential passwords in plain text
- Use K.PSGallery.LoggingModule for safe credential logging
- Mask sensitive information in error messages
- Validate all user input

### Testing
- Write Pester tests for all new functions
- Ensure tests don't require interactive input
- Mock external dependencies
- Test both success and failure scenarios

### Code Quality
- Pass PSScriptAnalyzer with no errors or warnings
- Use consistent formatting and indentation
- Add meaningful variable names
- Keep functions focused and single-purpose

## Provider Interface Contract

Each provider module must implement these functions:

```powershell
function Invoke-RegisterRepo {
    param($RepositoryName, $RegistryUri, $Credential, [switch]$Trusted)
}

function Invoke-Publish {
    param($RepositoryName, $ModulePath, $ModuleName, $Credential)
}

function Invoke-Install {
    param($RepositoryName, $ModuleName, $Version, $Credential, $Scope, [switch]$ImportAfterInstall)
}

function Invoke-RemoveRepo {
    param($RepositoryName)
}
```

## Common Patterns

### Error Handling
- Use proper exception types
- Provide actionable error messages
- Clean up resources on failure
- Use try/catch blocks appropriately

### Logging
- Use Write-Verbose for detailed operation logs
- Use Write-Warning for non-fatal issues
- Use Write-Error for failures
- Never expose credentials in logs

### Parameter Sets
- Use parameter sets for mutually exclusive options
- Provide sensible defaults
- Support pipeline input where appropriate

## Development Workflow

1. Create or update functions
2. Add/update comment-based help
3. Write or update Pester tests
4. Run tests locally: `Invoke-Pester -Path ./Tests/`
5. Run PSScriptAnalyzer: `Invoke-ScriptAnalyzer -Path . -Recurse`
6. Ensure all checks pass before committing

## Related Projects
- K.PSGallery.LoggingModule: Logging with credential masking
- K.PSGallery.PackageRepoProvider.GitHub: GitHub Packages provider
- K.PSGallery.PackageRepoProvider.GitLab: GitLab Package Registry provider
