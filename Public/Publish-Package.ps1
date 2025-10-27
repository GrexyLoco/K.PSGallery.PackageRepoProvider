function Publish-Package {
    <#
    .SYNOPSIS
        Publishes a module to a package registry.
    
    .DESCRIPTION
        Publishes a PowerShell module to a registered package registry.
        Supports auto-discovery of module manifests (.psd1) in the current directory.
    
    .PARAMETER RepositoryName
        The name of the registered repository.
    
    .PARAMETER ModulePath
        The path to the module directory. If not specified, uses auto-discovery.
    
    .PARAMETER ModuleName
        The name of the module to publish.
    
    .PARAMETER Credential
        Credentials for authenticating with the registry.
    
    .EXAMPLE
        $cred = Get-Credential
        Publish-Package -RepositoryName 'MyGitHub' -Credential $cred
        
        Publishes a module from the current directory (auto-discovery).
    
    .EXAMPLE
        $cred = Get-Credential
        Publish-Package -RepositoryName 'MyGitHub' -ModulePath './MyModule' -Credential $cred
        
        Publishes a specific module.
    #>
    [CmdletBinding(DefaultParameterSetName = 'AutoDiscovery')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(ParameterSetName = 'ExplicitPath')]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ModulePath,

        [Parameter()]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [pscredential]$Credential
    )
    
    # 1. Auto-discovery if ModulePath not specified
    if (-not $PSBoundParameters.ContainsKey('ModulePath')) {
        $ModulePath = Resolve-ModulePath -AutoDiscovery
        $PSBoundParameters['ModulePath'] = $ModulePath
    }
    
    # 2. Get provider from registered repository
    $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
    
    # 3. Load provider module
    $providerModule = Get-RepoProvider -Provider $provider
    
    # 4. Route to provider backend
    $invokeCommand = "$($providerModule.Name)\Invoke-Publish"
    & $invokeCommand @PSBoundParameters
    
    Write-Verbose "Successfully published package to repository '$RepositoryName' using $provider provider"
}
