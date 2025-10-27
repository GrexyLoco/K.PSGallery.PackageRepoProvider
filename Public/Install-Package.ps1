function Install-Package {
    <#
    .SYNOPSIS
        Installs a module from a package registry.
    
    .DESCRIPTION
        Installs a PowerShell module from a registered package registry.
        Supports flexible version specifications (v1, 1.2, 1.2.3, Latest).
    
    .PARAMETER RepositoryName
        The name of the registered repository.
    
    .PARAMETER ModuleName
        The name of the module to install.
    
    .PARAMETER Version
        The version to install. Supports:
        - 'v1' or '1' - Latest 1.x.x
        - '1.2' - Latest 1.2.x
        - '1.2.3' - Exact version
        - Empty/null - Latest version
    
    .PARAMETER Credential
        Credentials for authenticating with the registry.
    
    .PARAMETER Scope
        Installation scope: CurrentUser or AllUsers.
    
    .PARAMETER ImportAfterInstall
        Automatically imports the module after installation.
    
    .EXAMPLE
        $cred = Get-Credential
        Install-Package -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Credential $cred
        
        Installs the latest version of MyModule.
    
    .EXAMPLE
        $cred = Get-Credential
        Install-Package -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Version '1.2' -Credential $cred -ImportAfterInstall
        
        Installs the latest 1.2.x version and imports it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter()]
        [string]$Version,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [Parameter()]
        [switch]$ImportAfterInstall
    )
    
    # 1. Get provider from registered repository
    $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
    
    # 2. Load provider module
    $providerModule = Get-RepoProvider -Provider $provider
    
    # 3. Route to provider backend
    $invokeCommand = "$($providerModule.Name)\Invoke-Install"
    & $invokeCommand @PSBoundParameters
    
    # 4. Optional: Auto-import
    if ($ImportAfterInstall) {
        Import-PackageModule -ModuleName $ModuleName
    }
    
    Write-Verbose "Successfully installed package '$ModuleName' from repository '$RepositoryName' using $provider provider"
}
