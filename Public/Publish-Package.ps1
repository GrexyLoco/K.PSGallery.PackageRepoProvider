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
    
    .PARAMETER NupkgPath
        The path to a pre-built .nupkg file. When specified, publishes the .nupkg directly
        instead of packing from a module directory. This bypasses the Author Runspace Bug
        in PSResourceGet by using Publish-PSResource -NupkgPath.
    
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
    
    .EXAMPLE
        Publish-Package -RepositoryName 'MyGitHub' -NupkgPath './artifacts/MyModule.1.0.0.nupkg' -Token $env:GITHUB_TOKEN
        
        Publishes a pre-built .nupkg file (avoids Author Runspace Bug).
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

        [Parameter(Mandatory, ParameterSetName = 'NupkgCredential')]
        [Parameter(Mandatory, ParameterSetName = 'NupkgToken')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$NupkgPath,

        [Parameter()]
        [string]$ModuleName,

        [Parameter(Mandatory, ParameterSetName = 'AutoDiscoveryCredential')]
        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathCredential')]
        [Parameter(Mandatory, ParameterSetName = 'NupkgCredential')]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName = 'AutoDiscoveryToken')]
        [Parameter(Mandatory, ParameterSetName = 'ExplicitPathToken')]
        [Parameter(Mandatory, ParameterSetName = 'NupkgToken')]
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
    
    # 1. Determine publish mode: Nupkg or Path-based
    $publishMode = if ($PSBoundParameters.ContainsKey('NupkgPath')) { 'Nupkg' } else { 'Path' }
    
    # 2. Auto-discovery if ModulePath not specified (Path mode only)
    if ($publishMode -eq 'Path' -and -not $PSBoundParameters.ContainsKey('ModulePath')) {
        $ModulePath = Resolve-ModulePath -AutoDiscovery
    }
    
    # 3. Get provider from registered repository
    $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
    
    # 4. Load provider module
    $providerModule = Get-RepoProvider -Provider $provider
    
    # 5. Route to provider backend
    # Build parameters for provider (always pass Credential, not Token)
    $providerParams = @{
        RepositoryName = $RepositoryName
        Credential = $Credential
    }
    
    if ($publishMode -eq 'Nupkg') {
        # Nupkg mode: Pass pre-built .nupkg file
        $providerParams['NupkgPath'] = $NupkgPath
        Write-SafeInfoLog -Message "Publishing pre-built .nupkg to repository '$RepositoryName'" -Additional @{
            Repository = $RepositoryName
            Provider = $provider
            NupkgPath = $NupkgPath
        }
    }
    else {
        # Path mode: Pass module directory (legacy)
        $providerParams['ModulePath'] = $ModulePath
        if ($ModuleName) {
            $providerParams['ModuleName'] = $ModuleName
        }
        Write-SafeInfoLog -Message "Publishing module from path to repository '$RepositoryName'" -Additional @{
            Repository = $RepositoryName
            Provider = $provider
            ModulePath = $ModulePath
        }
    }
    
    $invokeCommand = "$($providerModule.Name)\Invoke-Publish"
    & $invokeCommand @providerParams
    
    Write-SafeInfoLog -Message "Successfully published package to repository '$RepositoryName' using $provider provider" -Additional @{
        Repository = $RepositoryName
        Provider = $provider
        PublishMode = $publishMode
    }
}
