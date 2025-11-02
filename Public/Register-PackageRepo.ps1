function Register-PackageRepo {
    <#
    .SYNOPSIS
        Registers a package registry as a PSResource repository.
    
    .DESCRIPTION
        Registers a private package registry (GitHub Packages, GitLab Package Registry) 
        as a PSResource repository. Automatically detects the provider type from the 
        registry URI and routes to the appropriate backend provider.
        
        Supports both PSCredential objects and token-based authentication for CI/CD scenarios.
    
    .PARAMETER RepositoryName
        The name to assign to the repository.
    
    .PARAMETER RegistryUri
        The URI of the package registry (e.g., https://nuget.pkg.github.com/myorg/index.json).
    
    .PARAMETER Credential
        PSCredential object for authenticating with the registry. Use this for interactive scenarios.
    
    .PARAMETER Token
        Personal Access Token (PAT) or API token for authenticating with the registry. 
        Use this for CI/CD scenarios where you have a token stored in secrets.
        When provided, a PSCredential will be created automatically using the token.
    
    .PARAMETER Trusted
        Marks the repository as trusted.
    
    .EXAMPLE
        $cred = Get-Credential
        Register-PackageRepo -RepositoryName 'MyGitHub' -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' -Credential $cred
        
        Registers a GitHub Packages repository using interactive credentials.
    
    .EXAMPLE
        Register-PackageRepo -RepositoryName 'MyGitHub' -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' -Token $env:GITHUB_TOKEN
        
        Registers a GitHub Packages repository using a token from environment variable (CI/CD scenario).
    
    .EXAMPLE
        $cred = Get-Credential
        Register-PackageRepo -RepositoryName 'MyGitLab' -RegistryUri 'https://gitlab.com/api/v4/projects/123/packages/nuget/index.json' -Credential $cred -Trusted
        
        Registers a GitLab Package Registry as trusted.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [uri]$RegistryUri,

        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName = 'Token')]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter()]
        [switch]$Trusted
    )
    
    try {
        # Convert Token to PSCredential if provided
        if ($PSCmdlet.ParameterSetName -eq 'Token') {
            $secureToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential('token', $secureToken)
        }
        
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
        # Build parameters for provider (always pass Credential, not Token)
        $providerParams = @{
            RepositoryName = $RepositoryName
            RegistryUri = $RegistryUri
            Credential = $Credential
        }
        if ($Trusted) {
            $providerParams['Trusted'] = $true
        }
        
        $invokeCommand = "$($providerModule.Name)\Invoke-RegisterRepo"
        & $invokeCommand @providerParams
        
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
