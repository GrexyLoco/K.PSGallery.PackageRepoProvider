function Install-PackageModule {
    <#
    .SYNOPSIS
        Installs a module from a package registry.
    
    .DESCRIPTION
        Installs a PowerShell module from a registered package registry.
        Supports flexible version specifications (v1, 1.2, 1.2.3, Latest).
        
        Supports both PSCredential objects and token-based authentication for CI/CD scenarios.
    
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
        PSCredential object for authenticating with the registry. Use this for interactive scenarios.
    
    .PARAMETER Token
        Personal Access Token (PAT) or API token for authenticating with the registry.
        Use this for CI/CD scenarios where you have a token stored in secrets.
    
    .PARAMETER Scope
        Installation scope: CurrentUser or AllUsers.
    
    .PARAMETER ImportAfterInstall
        Automatically imports the module after installation.
    
    .EXAMPLE
        $cred = Get-Credential
        Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Credential $cred
        
        Installs the latest version of MyModule.
    
    .EXAMPLE
        Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Token $env:GITHUB_TOKEN
        
        Installs the latest version using a token from environment variable (CI/CD scenario).
    
    .EXAMPLE
        $cred = Get-Credential
        Install-PackageModule -RepositoryName 'MyGitHub' -ModuleName 'MyModule' -Version '1.2' -Credential $cred -ImportAfterInstall
        
        Installs the latest 1.2.x version and imports it.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter()]
        [string]$Version,

        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [ValidateNotNull()]
        [pscredential]$Credential,

        [Parameter(Mandatory, ParameterSetName = 'Token')]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [Parameter()]
        [switch]$ImportAfterInstall
    )
    
    # Convert Token to PSCredential if provided
    if ($PSCmdlet.ParameterSetName -eq 'Token') {
        # Using SecureString constructor for CI/CD token handling
        # This is acceptable in automation scenarios where tokens come from secure vaults
        $secureToken = [System.Security.SecureString]::new()
        foreach ($char in $Token.ToCharArray()) {
            $secureToken.AppendChar($char)
        }
        $secureToken.MakeReadOnly()
        $Credential = [System.Management.Automation.PSCredential]::new('token', $secureToken)
    }
    
    # 1. Get provider from registered repository
    $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
    
    # 2. Load provider module
    $providerModule = Get-RepoProvider -Provider $provider
    
    # 3. Route to provider backend
    # Build parameters for provider (always pass Credential, not Token)
    $providerParams = @{
        RepositoryName = $RepositoryName
        ModuleName = $ModuleName
        Credential = $Credential
        Scope = $Scope
    }
    if ($Version) {
        $providerParams['Version'] = $Version
    }
    if ($ImportAfterInstall) {
        $providerParams['ImportAfterInstall'] = $true
    }
    
    $invokeCommand = "$($providerModule.Name)\Invoke-Install"
    & $invokeCommand @providerParams
    
    # 4. Optional: Auto-import (if provider didn't handle it)
    if ($ImportAfterInstall) {
        Import-PackageModule -ModuleName $ModuleName
    }
    
    Write-SafeInfoLog -Message "Successfully installed package '$ModuleName' from repository '$RepositoryName' using $provider provider" -Additional @{
        Module = $ModuleName
        Repository = $RepositoryName
        Provider = $provider
    }
}
