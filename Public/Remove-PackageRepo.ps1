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
    
    .EXAMPLE
        Remove-PackageRepo -RepositoryName 'MyGitHub' -WhatIf
        
        Shows what would happen if the repository was removed (without actually removing it).
    
    .EXAMPLE
        Remove-PackageRepo -RepositoryName 'MyGitHub' -Confirm:$false
        
        Removes the repository without confirmation prompt.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        
        # 3. ShouldProcess confirmation
        if ($PSCmdlet.ShouldProcess($RepositoryName, "Remove package repository")) {
            # 4. Route to provider backend
            $invokeCommand = "$($providerModule.Name)\Invoke-RemoveRepo"
            & $invokeCommand @PSBoundParameters
            
            # 5. Clean up provider registry
            if ($Script:ProviderRegistry -and $Script:ProviderRegistry.ContainsKey($RepositoryName)) {
                $Script:ProviderRegistry.Remove($RepositoryName)
            }
            
            Write-SafeInfoLog -Message "Successfully removed repository '$RepositoryName' using $provider provider" -Additional @{
                Repository = $RepositoryName
                Provider = $provider
            }
        }
    }
    catch {
        throw
    }
}
