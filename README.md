# K.PSGallery.PackageRepoProvider

PowerShell Aggregator/Facade for private package repositories (NuGet-compatible registries). Supports pluggable providers for GitHub Packages, GitLab Package Registry, and more.

## 🎯 Overview

This module provides a unified API for managing private PowerShell package repositories across different platforms (GitHub Packages, GitLab Package Registry). It automatically detects the provider type from the registry URI and routes commands to the appropriate backend provider.

## 📋 Features

- **Automatic Provider Detection**: Detects GitHub or GitLab from registry URI
- **Multi-Repository Support**: Manage multiple repositories simultaneously
- **Auto-Discovery**: Automatically finds module manifests for publishing
- **Flexible Version Handling**: Supports v1, 1.2, 1.2.3, or Latest
- **CI/CD Ready**: Supports both PSCredential and token-based authentication
- **Safe Credential Handling**: Integrates with K.PSGallery.LoggingModule for masked logging

## 📦 Installation

```powershell
# Install from PSGallery (when published)
Install-PSResource -Name K.PSGallery.PackageRepoProvider

# Or clone and import manually
git clone https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.git
Import-Module ./K.PSGallery.PackageRepoProvider
```

## 🚀 Quick Start

### Register a Repository

```powershell
# GitHub Packages (Interactive with credentials)
$cred = Get-Credential
Register-PackageRepo `
    -RepositoryName 'MyGitHub' `
    -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' `
    -Credential $cred `
    -Trusted

# GitHub Packages (CI/CD with token)
Register-PackageRepo `
    -RepositoryName 'MyGitHub' `
    -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' `
    -Token $env:GITHUB_TOKEN `
    -Trusted

# GitLab Package Registry
$cred = Get-Credential
Register-PackageRepo `
    -RepositoryName 'MyGitLab' `
    -RegistryUri 'https://gitlab.com/api/v4/projects/123/packages/nuget/index.json' `
    -Credential $cred
```

### Publish a Package

```powershell
# Auto-discovery (finds .psd1 in current directory)
$cred = Get-Credential
Publish-Package -RepositoryName 'MyGitHub' -Credential $cred

# CI/CD with token
Publish-Package -RepositoryName 'MyGitHub' -Token $env:GITHUB_TOKEN

# Explicit path
$cred = Get-Credential
Publish-Package `
    -RepositoryName 'MyGitHub' `
    -ModulePath './MyModule' `
    -Credential $cred
```

### Install a Package

```powershell
# Latest version (Interactive)
$cred = Get-Credential
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Credential $cred

# Latest version (CI/CD with token)
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Token $env:GITHUB_TOKEN

# Specific version (exact)
$cred = Get-Credential
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Version '1.2.3' `
    -Credential $cred

# Latest 1.x.x version (semantic version pattern)
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Version '1' `
    -Token $env:GITHUB_TOKEN

# Latest 1.2.x version
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Version '1.2' `
    -Token $env:GITHUB_TOKEN

# Install to AllUsers scope with auto-import
$cred = Get-Credential
Install-PackageModule `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Version '1.2.3' `
    -Credential $cred `
    -Scope AllUsers `
    -ImportAfterInstall
```

### Import a Module

```powershell
# By name
Import-PackageModule -ModuleName 'MyModule'

# By path with force reload
Import-PackageModule -ModulePath './MyModule' -Force
```

### List Available Providers

```powershell
# List all providers
Get-PackageRepoProvider

# Filter by name
Get-PackageRepoProvider -Name 'GitHub'
```

### Remove a Repository

```powershell
Remove-PackageRepo -RepositoryName 'MyGitHub'
```

## � API Reference

### Register-PackageRepo

Registers a package repository with automatic provider detection.

**Parameters:**
- `-RepositoryName` (string, required): Name for the repository
- `-RegistryUri` (uri, required): Registry URL (auto-detects provider from URL)
- `-Credential` (PSCredential, required*): Credentials for authentication (interactive)
- `-Token` (string, required*): PAT/API token for authentication (CI/CD)
- `-Trusted` (switch): Mark repository as trusted

*Either `-Credential` or `-Token` required

### Publish-Package

Publishes a module to a registered repository.

**Parameters:**
- `-RepositoryName` (string, required): Target repository name
- `-ModulePath` (string): Path to module directory (auto-discovers if omitted)
- `-ModuleName` (string): Expected module name for validation
- `-Credential` (PSCredential, required*): Credentials for authentication (interactive)
- `-Token` (string, required*): PAT/API token for authentication (CI/CD)

*Either `-Credential` or `-Token` required

### Install-PackageModule

Installs a module from a registered repository with flexible versioning.

**Parameters:**
- `-RepositoryName` (string, required): Source repository name
- `-ModuleName` (string, required): Name of module to install
- `-Version` (string): Version specification (`'1'`, `'1.2'`, `'1.2.3'`, or empty for latest)
- `-Credential` (PSCredential, required*): Credentials for authentication (interactive)
- `-Token` (string, required*): PAT/API token for authentication (CI/CD)
- `-Scope` (string): Installation scope - `'CurrentUser'` (default) or `'AllUsers'`
- `-ImportAfterInstall` (switch): Automatically import module after installation

*Either `-Credential` or `-Token` required

### Import-PackageModule

Imports an installed module into the current session.

**Parameters:**
- `-ModuleName` (string, required*): Name of module to import
- `-ModulePath` (string, required*): Path to module directory
- `-Force` (switch): Force reload if already imported

*Either `-ModuleName` or `-ModulePath` required

### Remove-PackageRepo

Unregisters a package repository.

**Parameters:**
- `-RepositoryName` (string, required): Name of repository to remove

### Get-PackageRepoProvider

Lists available provider modules.

**Parameters:**
- `-Name` (string): Filter providers by name

## �🔧 CI/CD Integration

All cmdlets that require authentication support both PSCredential objects and token-based authentication, making them ideal for CI/CD pipelines.

### GitHub Actions Example

```yaml
- name: Publish to Private Registry
  shell: pwsh
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    # Register the repository
    Register-PackageRepo `
      -RepositoryName 'MyPrivateRepo' `
      -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' `
      -Token $env:GITHUB_TOKEN `
      -Trusted
    
    # Publish the module
    Publish-Package `
      -RepositoryName 'MyPrivateRepo' `
      -Token $env:GITHUB_TOKEN
```

### GitLab CI Example

```yaml
publish:
  script:
    - |
      Register-PackageRepo `
        -RepositoryName 'MyGitLab' `
        -RegistryUri "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" `
        -Token $CI_JOB_TOKEN `
        -Trusted
      
      Publish-Package `
        -RepositoryName 'MyGitLab' `
        -Token $CI_JOB_TOKEN
```

### Token vs Credential

- **Token Parameter**: Use for CI/CD, scripts, and automation where you have a PAT or API token
- **Credential Parameter**: Use for interactive scenarios where you can use `Get-Credential`

Internally, tokens are converted to PSCredential objects before being passed to provider modules, ensuring consistent and secure handling.

## 🏗️ Architecture

### Provider Detection

The module automatically detects providers based on registry URI patterns:

- **GitHub**: Host contains `nuget.pkg.github.com`
- **GitLab**: Path contains `/packages/nuget/`

### Provider Interface

Each provider module implements the following functions:

- `Invoke-RegisterRepo`
- `Invoke-Publish`
- `Invoke-Install`
- `Invoke-RemoveRepo`

## 📁 Module Structure

```
K.PSGallery.PackageRepoProvider/
├── Public/              # Exported cmdlets
│   ├── Register-PackageRepo.ps1
│   ├── Publish-Package.ps1
│   ├── Install-PackageModule.ps1
│   ├── Import-PackageModule.ps1
│   ├── Remove-PackageRepo.ps1
│   └── Get-PackageRepoProvider.ps1
├── Private/             # Internal helper functions
│   ├── Resolve-ProviderFromUri.ps1
│   ├── Get-RepoProvider.ps1
│   ├── Resolve-ModulePath.ps1
│   └── Get-RegisteredRepoProvider.ps1
├── Tests/               # Pester tests
└── K.PSGallery.PackageRepoProvider.psd1
```

## 🔗 Dependencies

### Required Modules

- **K.PSGallery.LoggingModule**: Safe credential logging
- **PSResourceGet**: Microsoft's package management module

### Provider Modules (Optional)

- **K.PSGallery.PackageRepoProvider.GitHub**: GitHub Packages support
- **K.PSGallery.PackageRepoProvider.GitLab**: GitLab Package Registry support

## 📝 Version Flexibility

The `Install-PackageModule` cmdlet supports flexible version specifications similar to GitHub Actions:

- **`'1'` or `'v1'`** → Latest 1.x.x version (e.g., 1.9.5)
- **`'1.2'`** → Latest 1.2.x version (e.g., 1.2.8)
- **`'1.2.3'`** → Exact version 1.2.3
- **Empty/null** → Latest available version

This makes it easy to pin major or minor versions while getting patch updates automatically in CI/CD pipelines.

### Example Use Cases

```powershell
# CI/CD: Always get latest v1 (safe major version lock)
Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Version '1' -Token $env:GITHUB_TOKEN

# Development: Lock to 1.2.x for stability
Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Version '1.2' -Token $env:GITHUB_TOKEN

# Production: Exact version for reproducibility
Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Version '1.2.3' -Token $env:GITHUB_TOKEN
```

## 🧪 Testing

```powershell
# Run all tests
Invoke-Pester -Path ./Tests

# Run specific test file
Invoke-Pester -Path ./Tests/Private/Resolve-ProviderFromUri.Tests.ps1
```

## 🤝 Contributing

Contributions are welcome! Please ensure:

1. All tests pass with `Invoke-Pester`
2. Code passes `Invoke-ScriptAnalyzer` with no warnings
3. All public functions have comment-based help
4. Credentials are properly masked in logs

## 📄 License

See LICENSE file for details.

## 🔗 Related Projects

- [K.PSGallery](https://github.com/GrexyLoco/K.PSGallery) - Main project
- [K.PSGallery.PackageRepoProvider.GitHub](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub) - GitHub provider
- [K.PSGallery.PackageRepoProvider.GitLab](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitLab) - GitLab provider
