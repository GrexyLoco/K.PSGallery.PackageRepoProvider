<#
.SYNOPSIS
    Install PackageRepoProvider from local Git checkout (bootstrap mode).

.DESCRIPTION
    Loads K.PSGallery.PackageRepoProvider from current Git checkout.
    Used for bootstrap, breaking changes, and self-hosting scenarios.

.PARAMETER SecureToken
    GitHub PAT as SecureString for provider dependency installation
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$SecureToken
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "📦 Importing LOCAL K.PSGallery.PackageRepoProvider (bootstrap mode)..."
Write-Host "   Strategy: Self-hosting, current Git checkout"
Write-Host "   Path: ./K.PSGallery.PackageRepoProvider.psd1"
Write-Host ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)

# Pre-register GitHub Packages repository for provider dependencies
Write-Host "🔧 Pre-registering GitHub Packages repository..."
Register-PSResourceRepository -Name 'GrexyLoco-Bootstrap' `
    -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
    -Trusted `
    -Verbose

# Install GitHub Provider dependency (RequiredModules needs credentials for authenticated repos)
Write-Host ""
Write-Host "📥 Installing GitHub Provider from GitHub Packages..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub `
    -Repository 'GrexyLoco-Bootstrap' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

# Import local PackageRepoProvider
Write-Host ""
Write-Host "📂 Importing LOCAL PackageRepoProvider..."
Import-Module ./K.PSGallery.PackageRepoProvider.psd1 -Force -Verbose

Write-Host ""
Write-Host "✅ PackageRepoProvider loaded (LOCAL bootstrap)"
Write-Host "   ℹ️  GitHub Provider pre-installed for on-demand loading"
