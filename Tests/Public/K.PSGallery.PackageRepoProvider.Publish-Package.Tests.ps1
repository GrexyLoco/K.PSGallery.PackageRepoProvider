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

Describe 'Publish-Package' {
    Context 'Parameter Validation' {
        It 'Should have mandatory RepositoryName parameter' {
            (Get-Command Publish-Package).Parameters['RepositoryName'].Attributes.Mandatory | Should -Be $true
        }
        
        It 'Should have mandatory Credential parameter' {
            (Get-Command Publish-Package).Parameters['Credential'].Attributes.Mandatory | Should -Be $true
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
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Test constants
                $TestRepoName = "TestRepo"
                $TestProviderName = "GitHub"
                
                # Mock provider resolution and loading
                Mock Get-RegisteredRepoProvider { return $TestProviderName }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = $TestProviderName }
                }
                Mock Resolve-ModulePath { return $PWD.Path }
                
                # Create and mock the provider's Invoke-Publish function
                if (-not (Get-Command -Name 'GitHub\Invoke-Publish' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-Publish' -Value {
                        param($RepositoryName, $ModulePath, $Credential)
                    } -Force
                }
                Mock GitHub\Invoke-Publish { }
                
                $params = @{
                    RepositoryName = $TestRepoName
                    Credential = [pscredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
                }
                
                { Publish-Package @params } | Should -Not -Throw
                
                # Verify auto-discovery was called
                Should -Invoke Resolve-ModulePath -Times 1
            }
        }
    }
}
