BeforeAll {
    # Import required functions
    . $PSScriptRoot/../../Private/Resolve-ModulePath.ps1
    . $PSScriptRoot/../../Private/Get-RegisteredRepoProvider.ps1
    . $PSScriptRoot/../../Private/Get-RepoProvider.ps1
    . $PSScriptRoot/../../Public/Publish-Package.ps1
}

Describe 'Publish-Package' {
    Context 'Parameter Validation' {
        It 'Should require RepositoryName parameter' {
            { Publish-Package -Credential ([pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))) -ErrorAction Stop } | Should -Throw '*RepositoryName*'
        }
        
        It 'Should require Credential parameter' {
            { Publish-Package -RepositoryName 'TestRepo' -ErrorAction Stop } | Should -Throw '*Credential*'
        }
    }
    
    Context 'Auto-Discovery' {
        BeforeEach {
            # Initialize provider registry
            $Script:ProviderRegistry = @{ 'TestRepo' = 'GitHub' }
        }
        
        AfterEach {
            # Clean up
            Remove-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue
        }
        
        It 'Should use auto-discovery when ModulePath not specified' {
            Mock Get-RepoProvider { 
                return [PSCustomObject]@{ Name = 'K.PSGallery.PackageRepoProvider.GitHub' }
            }
            Mock Resolve-ModulePath { return '/test/path' }
            Mock Invoke-Expression -MockWith { } -ParameterFilter { $Command -like '*Invoke-Publish*' }
            
            $params = @{
                RepositoryName = 'TestRepo'
                Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            }
            
            Publish-Package @params
            Should -Invoke Resolve-ModulePath -Times 1
        }
    }
}
