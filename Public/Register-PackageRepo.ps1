function Register-PackageRepo {
    <#
    .SYNOPSIS
        Registers a package registry as a PSResource repository.
    
    .DESCRIPTION
        Registers a private package registry (GitHub Packages, GitLab Package Registry) 
        as a PSResource repository. Automatically detects the provider type from the 
        registry URI and routes to the appropriate backend provider.
    
    .PARAMETER RepositoryName
        The name to assign to the repository.
    
    .PARAMETER RegistryUri
        The URI of the package registry (e.g., https://nuget.pkg.github.com/myorg/index.json).
    
    .PARAMETER Credential
        Credentials for authenticating with the registry.
    
    .PARAMETER Trusted
        Marks the repository as trusted.
    
    .EXAMPLE
        $cred = Get-Credential
        Register-PackageRepo -RepositoryName 'MyGitHub' -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' -Credential $cred
        
        Registers a GitHub Packages repository.
    
    .EXAMPLE
        $cred = Get-Credential
        Register-PackageRepo -RepositoryName 'MyGitLab' -RegistryUri 'https://gitlab.com/api/v4/projects/123/packages/nuget/index.json' -Credential $cred -Trusted
        
        Registers a GitLab Package Registry as trusted.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [uri]$RegistryUri,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter()]
        [switch]$Trusted
    )
    
    try {
        # 1. Provider detection from RegistryUri
        $provider = Resolve-ProviderFromUri -RegistryUri $RegistryUri
        
        # 2. Load provider module
        $providerModule = Get-RepoProvider -Provider $provider
        
        # 3. Store provider mapping
        if (-not (Get-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue)) {
            $Script:ProviderRegistry = @{}
        }
        $Script:ProviderRegistry[$RepositoryName] = $provider
        
        # 4. Route to provider backend
        $invokeCommand = "$($providerModule.Name)\Invoke-RegisterRepo"
        & $invokeCommand @PSBoundParameters
        
        Write-Verbose "Successfully registered repository '$RepositoryName' using $provider provider"
    }
    catch {
        # Clean up provider registry on failure
        if ($Script:ProviderRegistry -and $Script:ProviderRegistry.ContainsKey($RepositoryName)) {
            $Script:ProviderRegistry.Remove($RepositoryName)
        }
        throw
    }
}
