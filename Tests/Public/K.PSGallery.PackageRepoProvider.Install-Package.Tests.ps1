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
    
    # Repository name constant for consistency across all tests
    $script:TestRepoName = "TestRepo"
    $script:TestProviderName = "GitHub"
}

Describe 'Install-Package' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should have mandatory RepositoryName parameter' {
            (Get-Command Install-Package).Parameters['RepositoryName'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Should have mandatory ModuleName parameter' {
            (Get-Command Install-Package).Parameters['ModuleName'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Should have mandatory Credential parameter' {
            (Get-Command Install-Package).Parameters['Credential'].Attributes.Mandatory | Should -Be $true
        }
    }

    Context 'Provider Routing' {
        It 'Should route to provider backend' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Test constants
                $TestRepoName = "TestRepo"
                $TestProviderName = "GitHub"
                
                # Mock Get-RegisteredRepoProvider to return the test provider name
                Mock Get-RegisteredRepoProvider { return $TestProviderName }
                
                # Mock Get-RepoProvider to return a mock module object
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = $TestProviderName }
                }
                
                # Create and mock the provider's Invoke-Install function in global scope
                # This simulates the provider module being loaded
                if (-not (Get-Command -Name 'GitHub\Invoke-Install' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-Install' -Value {
                        param($RepositoryName, $ModuleName, $Credential, $ImportAfterInstall)
                    } -Force
                }
                Mock GitHub\Invoke-Install { }
                
                $params = @{
                    RepositoryName = $TestRepoName
                    ModuleName = 'TestModule'
                    Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                }
                
                { Install-Package @params } | Should -Not -Throw
            }
        }
    }

    Context 'ImportAfterInstall' {
        It 'Should call Import-PackageModule when ImportAfterInstall is set' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Test constants
                $TestRepoName = "TestRepo"
                $TestProviderName = "GitHub"
                
                # Mock Get-RegisteredRepoProvider to return the test provider name
                Mock Get-RegisteredRepoProvider { return $TestProviderName }
                
                # Mock Get-RepoProvider to return a mock module object
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = $TestProviderName }
                }
                
                # Create and mock the provider's Invoke-Install function in global scope
                if (-not (Get-Command -Name 'GitHub\Invoke-Install' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-Install' -Value {
                        param($RepositoryName, $ModuleName, $Credential, $ImportAfterInstall)
                    } -Force
                }
                Mock GitHub\Invoke-Install { }
                Mock Import-PackageModule { }
                
                $params = @{
                    RepositoryName = $TestRepoName
                    ModuleName = 'TestModule'
                    Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                    ImportAfterInstall = $true
                }
                
                Install-Package @params
                Should -Invoke Import-PackageModule -Times 1
            }
        }
    }
}
