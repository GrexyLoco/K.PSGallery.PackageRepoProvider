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
Install-Package `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Credential $cred

# Latest version (CI/CD with token)
Install-Package `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Token $env:GITHUB_TOKEN

# Specific version
$cred = Get-Credential
Install-Package `
    -RepositoryName 'MyGitHub' `
    -ModuleName 'MyModule' `
    -Version '1.2.3' `
    -Credential $cred `
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

## 🔧 CI/CD Integration

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
│   ├── Install-Package.ps1
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

The `Install-Package` cmdlet supports flexible version specifications:

- `v1` or `1` → Latest 1.x.x version
- `1.2` → Latest 1.2.x version
- `1.2.3` → Exact version 1.2.3
- Empty/null → Latest version

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
