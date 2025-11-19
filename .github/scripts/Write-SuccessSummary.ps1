<#
.SYNOPSIS
    Write GitHub Actions success summary.

.DESCRIPTION
    Generates a formatted success summary for GitHub Actions UI.

.PARAMETER Context
    Publish context object with Repository, RegistryUri, LoadMode, ModuleName
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Context
)

$summary = @"
## ✅ Publish Successful

**Module:** ``$($Context.ModuleName)``

| Property | Value |
|----------|-------|
| 🎯 Repository | ``$($Context.Repository)`` |
| 🔗 Registry | ``$($Context.RegistryUri)`` |
| 🔄 Load Mode | $($Context.LoadMode) |
| 📦 Package URL | [View Package](https://github.com/GrexyLoco?tab=packages) |

### 🚀 Installation

``````powershell
# Register repository
Register-PackageRepo -RepositoryName '$($Context.Repository)' -RegistryUri '$($Context.RegistryUri)' -Token `$env:GITHUB_TOKEN -Trusted

# Install module
Install-PackageModule -RepositoryName '$($Context.Repository)' -ModuleName '$($Context.ModuleName)' -Token `$env:GITHUB_TOKEN
``````

### 📋 Version Options

``````powershell
# Latest version
Install-PackageModule -RepositoryName '$($Context.Repository)' -ModuleName '$($Context.ModuleName)' -Token `$env:GITHUB_TOKEN

# Latest 1.x.x
Install-PackageModule -RepositoryName '$($Context.Repository)' -ModuleName '$($Context.ModuleName)' -Version '1' -Token `$env:GITHUB_TOKEN

# Specific version
Install-PackageModule -RepositoryName '$($Context.Repository)' -ModuleName '$($Context.ModuleName)' -Version '0.1.0' -Token `$env:GITHUB_TOKEN
``````
"@

$summary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8
Write-Host "📊 Success summary written to GitHub Actions UI"
