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

#region Helper Functions

function Register-TemporaryRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory)]
        [string]$RepositoryUri
    )
    
    Write-Information "🔧 Registering temporary repository: $RepositoryName..."
    Register-PSResourceRepository -Name $RepositoryName `
        -Uri $RepositoryUri `
        -Trusted `
        -Verbose
}

function Install-PackageRepoProviderModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    
    Write-Information "📥 Installing K.PSGallery.PackageRepoProvider..."
    Install-PSResource -Name K.PSGallery.PackageRepoProvider `
        -Repository $RepositoryName `
        -Scope CurrentUser `
        -TrustRepository `
        -Credential $Credential `
        -Verbose
}

function Import-PackageRepoProviderModule {
    [CmdletBinding()]
    param()
    
    Write-Information "📂 Importing K.PSGallery.PackageRepoProvider..."
    Import-Module K.PSGallery.PackageRepoProvider -Force -Verbose
}

function Install-GitHubProviderModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    
    Write-Information "📥 Installing GitHub Provider from GitHub Packages..."
    Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub `
        -Repository $RepositoryName `
        -Scope CurrentUser `
        -TrustRepository `
        -Credential $Credential `
        -Verbose
}

function Install-LoggingModule {
    [CmdletBinding()]
    param()
    
    # TODO: Change to GitHub Packages after K.PSGallery.LoggingModule is published
    Write-Information "📦 Installing K.PSGallery.LoggingModule from PSGallery (temporary)..."
    Write-Information "   ⚠️  TODO: Migrate to GitHub Packages when available"
    
    try {
        Install-PSResource -Name K.PSGallery.LoggingModule `
            -Repository PSGallery `
            -Scope CurrentUser `
            -TrustRepository `
            -Verbose
        Write-Information "✅ LoggingModule installed from PSGallery"
    }
    catch {
        Write-Information "⚠️  LoggingModule installation failed (optional dependency)"
        Write-Information "   Error: $($_.Exception.Message)"
    }
}

#endregion

Write-Information ""
Write-Information "📦 Installing K.PSGallery.PackageRepoProvider from GitHub Packages..."
Write-Information "   Strategy: Stable, one-version-behind"
Write-Information "   Source: https://nuget.pkg.github.com/GrexyLoco/index.json"
Write-Information ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)
$repoName = 'GrexyLoco-Temp'
$repoUri = 'https://nuget.pkg.github.com/GrexyLoco/index.json'

# Register temporary repository
Register-TemporaryRepository -RepositoryName $repoName -RepositoryUri $repoUri

# Install PackageRepoProvider
Write-Information ""
Install-PackageRepoProviderModule -RepositoryName $repoName -Credential $credential

# Import PackageRepoProvider
Write-Information ""
Import-PackageRepoProviderModule

# Install GitHub Provider (RequiredModules doesn't auto-install from authenticated repos)
Write-Information ""
Install-GitHubProviderModule -RepositoryName $repoName -Credential $credential

# Install LoggingModule from PSGallery
Write-Information ""
Install-LoggingModule

Write-Information ""
Write-Information "✅ PackageRepoProvider loaded from GitHub Packages (stable)"
Write-Information "   ℹ️  GitHub Provider installed (pluggable architecture)"
