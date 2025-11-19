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
$InformationPreference = 'Continue'

Write-Information ""
Write-Information "📦 Importing LOCAL K.PSGallery.PackageRepoProvider (bootstrap mode)..."
Write-Information "   Strategy: Self-hosting, current Git checkout"
Write-Information "   Path: ./K.PSGallery.PackageRepoProvider.psd1"
Write-Information ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)

# Pre-register GitHub Packages repository for provider dependencies
Write-Information "🔧 Pre-registering GitHub Packages repository..."
Register-PSResourceRepository -Name 'GrexyLoco-Bootstrap' `
    -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
    -Trusted `
    -Verbose

# Install GitHub Provider dependency (RequiredModules needs credentials for authenticated repos)
Write-Information ""
Write-Information "📥 Installing GitHub Provider from GitHub Packages..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub `
    -Repository 'GrexyLoco-Bootstrap' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

# Import local PackageRepoProvider
Write-Information ""
Write-Information "📂 Importing LOCAL PackageRepoProvider..."
Import-Module ./K.PSGallery.PackageRepoProvider.psd1 -Force -Verbose

Write-Information ""
Write-Information "✅ PackageRepoProvider loaded (LOCAL bootstrap)"
Write-Information "   ℹ️  GitHub Provider pre-installed for on-demand loading"
