function Remove-PackageRepo {
    <#
    .SYNOPSIS
        Deregisters a package repository.
    
    .DESCRIPTION
        Removes a previously registered package repository from PSResource and 
        cleans up internal provider mappings.
    
    .PARAMETER RepositoryName
        The name of the repository to remove.
    
    .EXAMPLE
        Remove-PackageRepo -RepositoryName 'MyGitHub'
        
        Removes the MyGitHub repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryName
    )
    
    try {
        # 1. Get provider from registered repository
        $provider = Get-RegisteredRepoProvider -RepositoryName $RepositoryName
        
        # 2. Load provider module
        $providerModule = Get-RepoProvider -Provider $provider
        
        # 3. Route to provider backend
        $invokeCommand = "$($providerModule.Name)\Invoke-RemoveRepo"
        & $invokeCommand @PSBoundParameters
        
        # 4. Clean up provider registry
        if ($Script:ProviderRegistry -and $Script:ProviderRegistry.ContainsKey($RepositoryName)) {
            $Script:ProviderRegistry.Remove($RepositoryName)
        }
        
        Write-Verbose "Successfully removed repository '$RepositoryName' using $provider provider"
    }
    catch {
        throw
    }
}
