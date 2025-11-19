<#
.SYNOPSIS
    Initialize PowerShell environment for pipeline execution.

.DESCRIPTION
    Installs required PowerShell modules:
    - Microsoft.PowerShell.PSResourceGet (preview)
    - Microsoft.PowerShell.SecretManagement
    - K.PSGallery.LoggingModule (from PSGallery, temporary)
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host ""

# Install latest PREVIEW version of PSResourceGet (1.2.0-preview3 fixes "No author" bug)
Write-Host "📦 Installing Microsoft.PowerShell.PSResourceGet PREVIEW..."
Install-PSResource -Name Microsoft.PowerShell.PSResourceGet `
    -Prerelease `
    -Scope CurrentUser `
    -TrustRepository `
    -Reinstall `
    -Verbose

# Install SecretManagement (required dependency of PSResourceGet 1.2.0+)
Write-Host ""
Write-Host "📦 Installing Microsoft.PowerShell.SecretManagement..."
Install-PSResource -Name Microsoft.PowerShell.SecretManagement `
    -Scope CurrentUser `
    -TrustRepository `
    -Verbose

# Verify PSResourceGet version
$version = (Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | 
    Sort-Object Version -Descending | 
    Select-Object -First 1).Version
Write-Host ""
Write-Host "✅ PSResourceGet Version: $version"

# Install LoggingModule from PSGallery (temporary until published to GitHub Packages)
# TODO: Change to GitHub Packages after K.PSGallery.LoggingModule is published
Write-Host ""
Write-Host "📦 Installing K.PSGallery.LoggingModule from PSGallery (temporary)..."
Write-Host "   ⚠️  TODO: Migrate to GitHub Packages when available"
try {
    Install-PSResource -Name K.PSGallery.LoggingModule `
        -Repository PSGallery `
        -Scope CurrentUser `
        -TrustRepository `
        -Verbose
    Write-Host "✅ LoggingModule installed from PSGallery"
}
catch {
    Write-Host "⚠️  LoggingModule installation failed (optional dependency)"
    Write-Host "   Error: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "✅ Environment initialization complete"
