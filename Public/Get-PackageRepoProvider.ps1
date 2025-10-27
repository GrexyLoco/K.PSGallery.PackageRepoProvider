function Get-PackageRepoProvider {
    <#
    .SYNOPSIS
        Lists available package repository providers.
    
    .DESCRIPTION
        Shows all available provider modules that can be used with this aggregator.
        Providers follow the naming convention: K.PSGallery.PackageRepoProvider.<Provider>
    
    .PARAMETER Name
        Filter providers by name pattern.
    
    .EXAMPLE
        Get-PackageRepoProvider
        
        Lists all available providers.
    
    .EXAMPLE
        Get-PackageRepoProvider -Name 'GitHub'
        
        Shows details for the GitHub provider.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name
    )
    
    $providerPattern = 'K.PSGallery.PackageRepoProvider.*'
    
    if ($Name) {
        $providerPattern = "K.PSGallery.PackageRepoProvider.$Name"
    }
    
    # Get available provider modules
    $availableModules = Get-Module -ListAvailable -Name $providerPattern
    
    if (-not $availableModules) {
        Write-Warning "No provider modules found matching pattern '$providerPattern'"
        return
    }
    
    # Format output
    $providers = foreach ($module in $availableModules) {
        $providerName = $module.Name -replace 'K\.PSGallery\.PackageRepoProvider\.', ''
        
        [PSCustomObject]@{
            Provider = $providerName
            Version = $module.Version
            ModuleName = $module.Name
            Path = $module.ModuleBase
        }
    }
    
    return $providers
}
