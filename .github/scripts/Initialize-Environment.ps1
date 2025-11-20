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
$InformationPreference = 'Continue'

Write-Information "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Information ""

# Install latest PREVIEW version of PSResourceGet (1.2.0-preview3 fixes "No author" bug)
Write-Information "📦 Installing Microsoft.PowerShell.PSResourceGet PREVIEW..."
Install-PSResource -Name Microsoft.PowerShell.PSResourceGet `
    -Prerelease `
    -Scope CurrentUser `
    -TrustRepository `
    -Reinstall `
    -Verbose

# Install SecretManagement (required dependency of PSResourceGet 1.2.0+)
Write-Information ""
Write-Information "📦 Installing Microsoft.PowerShell.SecretManagement..."
Install-PSResource -Name Microsoft.PowerShell.SecretManagement `
    -Scope CurrentUser `
    -TrustRepository `
    -Verbose

# Verify PSResourceGet version
$version = (Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | 
    Sort-Object Version -Descending | 
    Select-Object -First 1).Version
Write-Information ""
Write-Information "✅ PSResourceGet Version: $version"

# Install LoggingModule from PSGallery (temporary until published to GitHub Packages)
# TODO: Change to GitHub Packages after K.PSGallery.LoggingModule is published
Write-Information ""
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

Write-Information ""
Write-Information "✅ Environment initialization complete"
