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
    
    .PARAMETER SkipNupkgBuild
        Skip automatic .nupkg pre-build. By default, the module builds a .nupkg first to avoid
        the Author Runspace Bug in PSResourceGet. Use this switch to publish directly from path
        (legacy behavior, may require -SkipModuleManifestValidate in provider).
    
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

        [Parameter()]
        [switch]$SkipNupkgBuild,

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
    
    # 1. Auto-discovery if ModulePath not specified (when not using pre-built .nupkg)
    if (-not $PSBoundParameters.ContainsKey('NupkgPath') -and -not $PSBoundParameters.ContainsKey('ModulePath')) {
        $ModulePath = Resolve-ModulePath -AutoDiscovery
    }
    
    # 2. Build .nupkg if publishing from path (avoids Author Runspace Bug)
    # Skip if -NupkgPath already provided or -SkipNupkgBuild specified
    $cleanupNupkg = $false
    if (-not $PSBoundParameters.ContainsKey('NupkgPath') -and -not $SkipNupkgBuild) {
        Write-SafeInfoLog -Message "Building .nupkg to bypass Author Runspace Bug" -Additional @{
            ModulePath = $ModulePath
        }
        
        # Create temporary artifacts directory
        $artifactsDir = Join-Path ([System.IO.Path]::GetTempPath()) "PSGallery-Artifacts-$([Guid]::NewGuid())"
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
        $cleanupNupkg = $true
        
        try {
            # Compress module to .nupkg
            $compressParams = @{
                Path = $ModulePath
                DestinationPath = $artifactsDir
            }
            
            Write-Verbose "Compressing module: $ModulePath to $artifactsDir"
            Compress-PSResource @compressParams -Verbose:$VerbosePreference
            
            # Find the created .nupkg file
            $nupkgFile = Get-ChildItem -Path $artifactsDir -Filter "*.nupkg" | Select-Object -First 1
            
            if (-not $nupkgFile) {
                throw "Failed to create .nupkg file in $artifactsDir"
            }
            
            $NupkgPath = $nupkgFile.FullName
            Write-SafeInfoLog -Message ".nupkg created successfully" -Additional @{
                NupkgPath = $NupkgPath
                Size = "$([math]::Round($nupkgFile.Length / 1KB, 2)) KB"
            }
        }
        catch {
            # Cleanup on failure
            if ($cleanupNupkg -and (Test-Path $artifactsDir)) {
                Remove-Item -Path $artifactsDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            throw
        }
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
    
    try {
        if ($PSBoundParameters.ContainsKey('NupkgPath') -or -not $SkipNupkgBuild) {
            # Nupkg mode: Pass pre-built .nupkg file
            $providerParams['NupkgPath'] = $NupkgPath
            Write-SafeInfoLog -Message "Publishing .nupkg to repository '$RepositoryName'" -Additional @{
                Repository = $RepositoryName
                Provider = $provider
                NupkgPath = $NupkgPath
            }
        }
        else {
            # Legacy path mode: Pass module directory (may require -SkipModuleManifestValidate in provider)
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
        }
    }
    finally {
        # Cleanup temporary .nupkg if we created it
        if ($cleanupNupkg -and (Test-Path $artifactsDir)) {
            Write-Verbose "Cleaning up temporary artifacts: $artifactsDir"
            Remove-Item -Path $artifactsDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
