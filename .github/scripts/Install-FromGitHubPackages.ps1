<#
.SYNOPSIS
    Install PackageRepoProvider from GitHub Packages (stable mode).

.DESCRIPTION
    Loads K.PSGallery.PackageRepoProvider from published GitHub Packages.
    Uses one-version-behind strategy for stability.

.PARAMETER SecureToken
    GitHub PAT as SecureString for authentication
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$SecureToken
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Write-Information ""
Write-Information "📦 Installing K.PSGallery.PackageRepoProvider from GitHub Packages..."
Write-Information "   Strategy: Stable, one-version-behind"
Write-Information "   Source: https://nuget.pkg.github.com/GrexyLoco/index.json"
Write-Information ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)

# Register temporary repository (no credentials stored)
Write-Information "🔧 Registering temporary repository..."
Register-PSResourceRepository -Name 'GrexyLoco-Temp' `
    -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
    -Trusted `
    -Verbose

# Install PackageRepoProvider from GitHub Packages
Write-Information ""
Write-Information "📥 Installing K.PSGallery.PackageRepoProvider..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider `
    -Repository 'GrexyLoco-Temp' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

# Import module
Write-Information ""
Write-Information "📂 Importing K.PSGallery.PackageRepoProvider..."
Import-Module K.PSGallery.PackageRepoProvider -Force -Verbose

# Install GitHub Provider (RequiredModules doesn't auto-install from authenticated repos)
Write-Information ""
Write-Information "📥 Installing GitHub Provider from GitHub Packages..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub `
    -Repository 'GrexyLoco-Temp' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

Write-Information ""
Write-Information "✅ PackageRepoProvider loaded from GitHub Packages (stable)"
Write-Information "   ℹ️  GitHub Provider installed (pluggable architecture)"
