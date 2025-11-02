BeforeAll {
    # Import the module using absolute path
    $modulePath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path $modulePath "K.PSGallery.PackageRepoProvider.psd1"
    
    # Remove if already loaded to ensure fresh import
    if (Get-Module K.PSGallery.PackageRepoProvider) {
        Remove-Module K.PSGallery.PackageRepoProvider -Force
    }
    
    Import-Module $manifestPath -Force -Verbose
    
    # Verify module is loaded
    $loadedModule = Get-Module K.PSGallery.PackageRepoProvider
    if (-not $loadedModule) {
        throw "Failed to load module K.PSGallery.PackageRepoProvider from $manifestPath"
    }
}

Describe 'Register-PackageRepo' {
    Context 'Parameter Validation' {
        It 'Should have mandatory RepositoryName parameter' {
            (Get-Command Register-PackageRepo).Parameters['RepositoryName'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Should have mandatory RegistryUri parameter' {
            (Get-Command Register-PackageRepo).Parameters['RegistryUri'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Should have Credential parameter in Credential parameter set' {
            $credentialParam = (Get-Command Register-PackageRepo).Parameters['Credential']
            $credentialParam | Should -Not -BeNullOrEmpty
            $credentialParam.ParameterSets['Credential'].IsMandatory | Should -Be $true
        }
        
        It 'Should have Token parameter in Token parameter set' {
            $tokenParam = (Get-Command Register-PackageRepo).Parameters['Token']
            $tokenParam | Should -Not -BeNullOrEmpty
            $tokenParam.ParameterSets['Token'].IsMandatory | Should -Be $true
        }
        
        It 'Should have both Credential and Token parameter sets' {
            $paramSets = (Get-Command Register-PackageRepo).ParameterSets.Name
            $paramSets | Should -Contain 'Credential'
            $paramSets | Should -Contain 'Token'
        }
    }
    
    Context 'Provider Detection' {
        It 'Should detect GitHub provider from URI' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Mock provider resolution and loading
                Mock Resolve-ProviderFromUri { return 'GitHub' }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = 'GitHub' }
                }
                
                # Create and mock the provider's Invoke-RegisterRepo function
                if (-not (Get-Command -Name 'GitHub\Invoke-RegisterRepo' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-RegisterRepo' -Value {
                        param($RepositoryName, $RegistryUri, $Credential)
                    } -Force
                }
                Mock GitHub\Invoke-RegisterRepo { }
                
                $params = @{
                    RepositoryName = 'GitHubRepo'
                    RegistryUri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
                    Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                }
                
                { Register-PackageRepo @params } | Should -Not -Throw
            }
        }
        
        It 'Should store provider mapping' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Mock provider resolution and loading
                Mock Resolve-ProviderFromUri { return 'GitHub' }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = 'GitHub' }
                }
                
                # Create and mock the provider's Invoke-RegisterRepo function
                if (-not (Get-Command -Name 'GitHub\Invoke-RegisterRepo' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-RegisterRepo' -Value {
                        param($RepositoryName, $RegistryUri, $Credential)
                    } -Force
                }
                Mock GitHub\Invoke-RegisterRepo { }
                
                $params = @{
                    RepositoryName = 'GitHubRepo'
                    RegistryUri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
                    Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                }
                
                Register-PackageRepo @params
                
                # Verify provider registry was updated
                $Script:ProviderRegistry['GitHubRepo'] | Should -Be 'GitHub'
            }
        }
        
        It 'Should support token-based authentication' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Mock provider resolution and loading
                Mock Resolve-ProviderFromUri { return 'GitHub' }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = 'GitHub' }
                }
                
                # Create and mock the provider's Invoke-RegisterRepo function
                if (-not (Get-Command -Name 'GitHub\Invoke-RegisterRepo' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-RegisterRepo' -Value {
                        param($RepositoryName, $RegistryUri, $Credential)
                    } -Force
                }
                Mock GitHub\Invoke-RegisterRepo { }
                
                $params = @{
                    RepositoryName = 'GitHubRepoToken'
                    RegistryUri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
                    Token = 'ghp_test123token'
                }
                
                { Register-PackageRepo @params } | Should -Not -Throw
                
                # Verify provider registry was updated
                $Script:ProviderRegistry['GitHubRepoToken'] | Should -Be 'GitHub'
            }
        }
    }
}
