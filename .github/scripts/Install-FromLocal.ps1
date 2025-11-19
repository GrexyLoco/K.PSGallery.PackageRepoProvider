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

#region Helper Functions

function Register-BootstrapRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory)]
        [string]$RepositoryUri
    )
    
    Write-Information "🔧 Pre-registering GitHub Packages repository: $RepositoryName..."
    Register-PSResourceRepository -Name $RepositoryName `
        -Uri $RepositoryUri `
        -Trusted `
        -Verbose
}

function Install-LocalGitHubProvider {
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

function Import-GitHubProvider {
    [CmdletBinding()]
    param()
    
    Write-Information "📂 Importing GitHub Provider..."
    Import-Module K.PSGallery.PackageRepoProvider.GitHub -Force -Verbose
}

function Import-LocalPackageRepoProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )
    
    Write-Information "📂 Importing LOCAL PackageRepoProvider from: $ManifestPath..."
    Import-Module $ManifestPath -Force -Verbose
}

#endregion

Write-Information ""
Write-Information "📦 Importing LOCAL K.PSGallery.PackageRepoProvider (bootstrap mode)..."
Write-Information "   Strategy: Self-hosting, current Git checkout"
Write-Information "   Path: ./K.PSGallery.PackageRepoProvider.psd1"
Write-Information ""

# Convert SecureString to PSCredential
$credential = [PSCredential]::new('token', $SecureToken)
$repoName = 'GrexyLoco-Bootstrap'
$repoUri = 'https://nuget.pkg.github.com/GrexyLoco/index.json'
$localManifest = './K.PSGallery.PackageRepoProvider.psd1'

# Pre-register GitHub Packages repository for provider dependencies
Register-BootstrapRepository -RepositoryName $repoName -RepositoryUri $repoUri

# Install GitHub Provider dependency
Write-Information ""
Install-LocalGitHubProvider -RepositoryName $repoName -Credential $credential

# Import GitHub Provider to verify availability
Write-Information ""
Import-GitHubProvider

# Import local PackageRepoProvider
Write-Information ""
Import-LocalPackageRepoProvider -ManifestPath $localManifest

Write-Information ""
Write-Information "✅ PackageRepoProvider loaded (LOCAL bootstrap)"
Write-Information "   ℹ️  GitHub Provider pre-installed and imported"
