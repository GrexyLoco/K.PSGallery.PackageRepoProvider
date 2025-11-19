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

Write-Host ""
Write-Host "📦 Installing K.PSGallery.PackageRepoProvider from GitHub Packages..."
Write-Host "   Strategy: Stable, one-version-behind"
Write-Host "   Source: https://nuget.pkg.github.com/GrexyLoco/index.json"
Write-Host ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)

# Register temporary repository (no credentials stored)
Write-Host "🔧 Registering temporary repository..."
Register-PSResourceRepository -Name 'GrexyLoco-Temp' `
    -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
    -Trusted `
    -Verbose

# Install PackageRepoProvider from GitHub Packages
Write-Host ""
Write-Host "📥 Installing K.PSGallery.PackageRepoProvider..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider `
    -Repository 'GrexyLoco-Temp' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

# Import module
Write-Host ""
Write-Host "📂 Importing K.PSGallery.PackageRepoProvider..."
Import-Module K.PSGallery.PackageRepoProvider -Force -Verbose

# Install GitHub Provider (RequiredModules doesn't auto-install from authenticated repos)
Write-Host ""
Write-Host "📥 Installing GitHub Provider from GitHub Packages..."
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub `
    -Repository 'GrexyLoco-Temp' `
    -Scope CurrentUser `
    -TrustRepository `
    -Credential $credential `
    -Verbose

Write-Host ""
Write-Host "✅ PackageRepoProvider loaded from GitHub Packages (stable)"
Write-Host "   ℹ️  GitHub Provider installed (pluggable architecture)"
