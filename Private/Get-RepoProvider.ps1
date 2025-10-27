function Get-RepoProvider {
    <#
    .SYNOPSIS
        Gets the provider module for a specific provider type.
    
    .DESCRIPTION
        Loads and returns the provider module for the specified provider backend.
        Provider modules follow the naming convention: K.PSGallery.PackageRepoProvider.<Provider>
    
    .PARAMETER Provider
        The provider type (e.g., 'GitHub', 'GitLab').
    
    .EXAMPLE
        Get-RepoProvider -Provider 'GitHub'
        Returns: Module object for K.PSGallery.PackageRepoProvider.GitHub
    #>
    [CmdletBinding()]
    [OutputType([PSModuleInfo])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Provider
    )
    
    $moduleName = "K.PSGallery.PackageRepoProvider.$Provider"
    
    # Check if module is already loaded
    $loadedModule = Get-Module -Name $moduleName
    if ($loadedModule) {
        return $loadedModule
    }
    
    # Try to import the module
    try {
        $module = Import-Module -Name $moduleName -PassThru -ErrorAction Stop
        return $module
    }
    catch {
        throw "Failed to load provider module '$moduleName'. Ensure the provider is installed. Error: $_"
    }
}
