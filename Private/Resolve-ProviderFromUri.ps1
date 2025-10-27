function Resolve-ProviderFromUri {
    <#
    .SYNOPSIS
        Resolves the provider type from a registry URI.
    
    .DESCRIPTION
        Analyzes the registry URI to determine which provider backend should be used.
        - GitHub: Host contains 'nuget.pkg.github.com'
        - GitLab: Path contains '/packages/nuget/'
    
    .PARAMETER RegistryUri
        The URI of the package registry.
    
    .EXAMPLE
        Resolve-ProviderFromUri -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json'
        Returns: 'GitHub'
    
    .EXAMPLE
        Resolve-ProviderFromUri -RegistryUri 'https://gitlab.com/api/v4/projects/123/packages/nuget/index.json'
        Returns: 'GitLab'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [uri]$RegistryUri
    )
    
    # Check for GitHub
    if ($RegistryUri.Host -like '*nuget.pkg.github.com*') {
        return 'GitHub'
    }
    
    # Check for GitLab
    if ($RegistryUri.AbsolutePath -like '*/packages/nuget/*') {
        return 'GitLab'
    }
    
    # Unknown provider
    throw "Unable to determine provider from registry URI: $($RegistryUri.AbsoluteUri). Supported: GitHub (nuget.pkg.github.com), GitLab (/packages/nuget/)"
}
