function Get-RegisteredRepoProvider {
    <#
    .SYNOPSIS
        Gets the provider type for a registered repository.
    
    .DESCRIPTION
        Retrieves the provider type associated with a registered PSResource repository.
        Stores provider mappings in module-scoped variable.
    
    .PARAMETER RepositoryName
        The name of the registered repository.
    
    .EXAMPLE
        Get-RegisteredRepoProvider -RepositoryName 'MyPrivateRepo'
        Returns: 'GitHub'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName
    )
    
    # Initialize module-scoped variable if not exists
    if (-not (Get-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue)) {
        $Script:ProviderRegistry = @{}
    }
    
    # Check if repository is registered
    if (-not $Script:ProviderRegistry.ContainsKey($RepositoryName)) {
        throw "Repository '$RepositoryName' is not registered. Use Register-PackageRepo to register it first."
    }
    
    return $Script:ProviderRegistry[$RepositoryName]
}
