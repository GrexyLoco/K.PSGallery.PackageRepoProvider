<#
.SYNOPSIS
    Publish module to GitHub Packages using PackageRepoProvider.

.DESCRIPTION
    Registers repository and publishes K.PSGallery.PackageRepoProvider to GitHub Packages.
    Handles both success and error scenarios with GitHub Actions summaries.

.PARAMETER SecureToken
    GitHub PAT as SecureString for authentication

.PARAMETER UseGitHubPackages
    Whether PackageRepoProvider was loaded from GitHub Packages (for summary)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$SecureToken,
    
    [bool]$UseGitHubPackages = $false
)

$ErrorActionPreference = 'Stop'

# Convert SecureString to plaintext for API calls (trusted environment)
$credential = [PSCredential]::new('token', $SecureToken)
$token = $credential.GetNetworkCredential().Password

# Repository configuration
$repoName = "1d70f-Repo"
$registryUri = "https://nuget.pkg.github.com/GrexyLoco/index.json"

# Context for summaries
$context = [PSCustomObject]@{
    Repository = $repoName
    RegistryUri = $registryUri
    LoadMode = if ($UseGitHubPackages) { "📦 GitHub Packages (stable)" } else { "🏗️ LOCAL Bootstrap" }
    ModuleName = "K.PSGallery.PackageRepoProvider"
}

try {
    # Register GitHub Packages repository
    Write-Host ""
    Write-Host "🔧 Registering repository: $repoName"
    Write-Host "   URI: $registryUri"
    Register-PackageRepo -RepositoryName $repoName -RegistryUri $registryUri -Token $token -Trusted
    
    # Publish using PackageRepoProvider public API
    Write-Host ""
    Write-Host "📤 Publishing K.PSGallery.PackageRepoProvider to GitHub Packages..."
    Publish-Package -RepositoryName $repoName -Token $token
    
    Write-Host ""
    Write-Host "✅ Module published successfully to GitHub Packages!"
    
    # Write success summary
    & "$PSScriptRoot/Write-SuccessSummary.ps1" -Context $context
}
catch {
    Write-Host ""
    Write-Host "❌ PUBLISH FAILED" -ForegroundColor Red
    Write-Host "💥 Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Add error to context
    $context | Add-Member -NotePropertyName 'Error' -NotePropertyValue $_.Exception.Message -Force
    $context | Add-Member -NotePropertyName 'TokenPresent' -NotePropertyValue ($null -ne $token -and $token.Length -gt 0) -Force
    
    # Write error summary
    & "$PSScriptRoot/Write-ErrorSummary.ps1" -Context $context
    
    throw
}
