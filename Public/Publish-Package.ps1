function Publish-Package {
    <#
    .SYNOPSIS
        Publishes a module to a package registry.
    
    .DESCRIPTION
        Publishes a PowerShell module to a registered package registry.
        Supports auto-discovery of module manifests (.psd1) in the current directory.
        
        Supports both PSCredential objects and token-based authentication for CI/CD scenarios.
    
    .PARAMETER RepositoryName
        The name of the registered repository.
    
    .PARAMETER ModulePath
        The path to the module directory. If not specified, uses auto-discovery.
    
    .PARAMETER ModuleName
        The name of the module to publish.
    
    .PARAMETER Credential
        PSCredential object for authenticating with the registry. Use this for interactive scenarios.
    
    .PARAMETER Token
        Personal Access Token (PAT) or API token for authenticating with the registry.
        Use this for CI/CD scenarios where you have a token stored in secrets.
    
    .EXAMPLE
        $cred = Get-Credential
        Publish-Package -RepositoryName 'MyGitHub' -Credential $cred
        
        Publishes a module from the current directory (auto-discovery).
    
    .EXAMPLE
        Publish-Package -RepositoryName 'MyGitHub' -Token $env:GITHUB_TOKEN
        
        Publishes a module using a token from environment variable (CI/CD scenario).
    
    .EXAMPLE
        $cred = Get-Credential
        Publish-Package -RepositoryName 'MyGitHub' -ModulePath './MyModule' -Credential $cred
        
        Publishes a specific module.
    #>
    [CmdletBinding(DefaultParameterSetName = 'AutoDiscoveryCredential')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathCredential')]
        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathToken')]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ModulePath,

        [Parameter()]
        [string]$ModuleName,

        [Parameter(Mandatory, ParameterSetName = 'AutoDiscoveryCredential')]
        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathCredential')]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName = 'AutoDiscoveryToken')]
        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathToken')]
        [ValidateNotNullOrEmpty()]
        [string]$Token
    )
    
    # Convert Token to PSCredential if provided
    if ($PSCmdlet.ParameterSetName -like '*Token') {
        # Using SecureString constructor for CI/CD token handling
        # This is acceptable in automation scenarios where tokens come from secure vaults
        $secureToken = [System.Security.SecureString]::new()
        foreach ($char in $Token.ToCharArray()) {
            $secureToken.AppendChar($char)
        }
        $secureToken.MakeReadOnly()
        $Credential = [System.Management.Automation.PSCredential]::new('token', $secureToken)
    }
    
    # 1. Auto-discovery if ModulePath not specified
    if (-not $PSBoundParameters.ContainsKey('ModulePath')) {
        $ModulePath = Resolve-ModulePath -AutoDiscovery
    }
    
    # 2. Get provider from registered repository
    $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
    
    # 3. Load provider module
    $providerModule = Get-RepoProvider -Provider $provider
    
    # 4. Route to provider backend
    # Build parameters for provider (always pass Credential, not Token)
    $providerParams = @{
        RepositoryName = $RepositoryName
        ModulePath = $ModulePath
        Credential = $Credential
    }
    if ($ModuleName) {
        $providerParams['ModuleName'] = $ModuleName
    }
    
    $invokeCommand = "$($providerModule.Name)\Invoke-Publish"
    & $invokeCommand @providerParams
    
    Write-LogInfo "Successfully published package to repository '$RepositoryName' using $provider provider"
    Write-LogDebug @{
        Repository = $RepositoryName
        Provider = $provider
        ModulePath = $ModulePath
    }
}
