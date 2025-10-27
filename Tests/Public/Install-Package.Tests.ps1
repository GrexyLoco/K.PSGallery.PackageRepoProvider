BeforeAll {
    # Import required functions
    . $PSScriptRoot/../../Private/Get-RegisteredRepoProvider.ps1
    . $PSScriptRoot/../../Private/Get-RepoProvider.ps1
    . $PSScriptRoot/../../Public/Import-PackageModule.ps1
    . $PSScriptRoot/../../Public/Install-Package.ps1
}

Describe 'Install-Package' {
    Context 'Parameter Validation' {
        It 'Should require RepositoryName parameter' {
            { Install-Package -ModuleName 'TestModule' -Credential ([pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))) -ErrorAction Stop } | Should -Throw '*RepositoryName*'
        }
        
        It 'Should require ModuleName parameter' {
            { Install-Package -RepositoryName 'TestRepo' -Credential ([pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))) -ErrorAction Stop } | Should -Throw '*ModuleName*'
        }
    }
    
    Context 'Provider Routing' {
        BeforeEach {
            # Initialize provider registry
            $Script:ProviderRegistry = @{ 'TestRepo' = 'GitHub' }
        }
        
        AfterEach {
            # Clean up
            Remove-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue
        }
        
        It 'Should route to provider backend' {
            Mock Get-RepoProvider { 
                return [PSCustomObject]@{ Name = 'K.PSGallery.PackageRepoProvider.GitHub' }
            }
            
            # Mock the invoke command using a script block
            Mock Invoke-Expression -MockWith { } -ParameterFilter { $Command -like '*Invoke-Install*' }
            
            $params = @{
                RepositoryName = 'TestRepo'
                ModuleName = 'TestModule'
                Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            }
            
            { Install-Package @params } | Should -Not -Throw
        }
    }
    
    Context 'ImportAfterInstall' {
        BeforeEach {
            # Initialize provider registry
            $Script:ProviderRegistry = @{ 'TestRepo' = 'GitHub' }
        }
        
        AfterEach {
            # Clean up
            Remove-Variable -Name 'Script:ProviderRegistry' -Scope Script -ErrorAction SilentlyContinue
        }
        
        It 'Should call Import-PackageModule when ImportAfterInstall is set' {
            Mock Get-RepoProvider { 
                return [PSCustomObject]@{ Name = 'K.PSGallery.PackageRepoProvider.GitHub' }
            }
            Mock Invoke-Expression -MockWith { } -ParameterFilter { $Command -like '*Invoke-Install*' }
            Mock Import-PackageModule { }
            
            $params = @{
                RepositoryName = 'TestRepo'
                ModuleName = 'TestModule'
                Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                ImportAfterInstall = $true
            }
            
            Install-Package @params
            Should -Invoke Import-PackageModule -Times 1
        }
    }
}
