BeforeAll {
    # Import required functions
    . $PSScriptRoot/../../Private/Resolve-ProviderFromUri.ps1
    . $PSScriptRoot/../../Private/Get-RepoProvider.ps1
    . $PSScriptRoot/../../Public/Register-PackageRepo.ps1
}

Describe 'Register-PackageRepo' {
    BeforeEach {
        # Clear provider registry
        if (Get-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue) {
            Remove-Variable -Name 'Script:ProviderRegistry' -Scope Script
        }
    }
    
    Context 'Parameter Validation' {
        It 'Should require RepositoryName parameter' {
            { Register-PackageRepo -RegistryUri ([uri]'https://nuget.pkg.github.com/myorg/index.json') -Credential ([pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))) -ErrorAction Stop } | Should -Throw '*RepositoryName*'
        }
        
        It 'Should require RegistryUri parameter' {
            { Register-PackageRepo -RepositoryName 'TestRepo' -Credential ([pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))) -ErrorAction Stop } | Should -Throw '*RegistryUri*'
        }
        
        It 'Should require Credential parameter' {
            { Register-PackageRepo -RepositoryName 'TestRepo' -RegistryUri ([uri]'https://nuget.pkg.github.com/myorg/index.json') -ErrorAction Stop } | Should -Throw '*Credential*'
        }
    }
    
    Context 'Provider Detection' {
        It 'Should detect GitHub provider from URI' {
            Mock Get-RepoProvider { 
                return [PSCustomObject]@{ Name = 'K.PSGallery.PackageRepoProvider.GitHub' }
            }
            Mock Invoke-Expression -MockWith { } -ParameterFilter { $Command -like '*Invoke-RegisterRepo*' }
            
            $params = @{
                RepositoryName = 'GitHubRepo'
                RegistryUri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
                Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            }
            
            { Register-PackageRepo @params } | Should -Not -Throw
        }
        
        It 'Should store provider mapping' {
            Mock Get-RepoProvider { 
                return [PSCustomObject]@{ Name = 'K.PSGallery.PackageRepoProvider.GitHub' }
            }
            Mock Invoke-Expression -MockWith { } -ParameterFilter { $Command -like '*Invoke-RegisterRepo*' }
            
            $params = @{
                RepositoryName = 'GitHubRepo'
                RegistryUri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
                Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            }
            
            Register-PackageRepo @params
            
            $Script:ProviderRegistry['GitHubRepo'] | Should -Be 'GitHub'
        }
    }
}
