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
        
        It 'Should have Credential parameter mandatory in Credential parameter sets' {
            $credentialParam = (Get-Command Publish-Package).Parameters['Credential']
            $mandatoryAttributes = $credentialParam.Attributes | Where-Object { $_.Mandatory -eq $true }
            $mandatoryAttributes.Count | Should -BeGreaterThan 0
        }
        
        It 'Should have Token parameter in Token parameter sets' {
            $tokenParam = (Get-Command Publish-Package).Parameters['Token']
            $tokenParam | Should -Not -BeNullOrEmpty
            $tokenAttributes = $tokenParam.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' }
            $tokenParameterSets = $tokenAttributes | Where-Object { $_.ParameterSetName -like '*Token' }
            $tokenParameterSets | Should -Not -BeNullOrEmpty
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
                $TestNupkgPath = Join-Path ([System.IO.Path]::GetTempPath()) "TestModule.1.0.0.nupkg"
                
                # Mock provider resolution and loading
                Mock Get-RegisteredRepoProvider { return $TestProviderName }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = $TestProviderName }
                }
                Mock Resolve-ModulePath { return $PWD.Path }
                
                # Mock Compress-PSResource to avoid actual compression
                Mock Compress-PSResource { }
                
                # Mock Get-ChildItem to return a fake .nupkg file
                Mock Get-ChildItem {
                    return [PSCustomObject]@{
                        FullName = $TestNupkgPath
                        Length = 1024
                    }
                } -ParameterFilter { $Filter -eq '*.nupkg' }
                
                # Create and mock the provider's Invoke-Publish function
                if (-not (Get-Command -Name 'GitHub\Invoke-Publish' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-Publish' -Value {
                        param($RepositoryName, $NupkgPath, $Credential)
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
        
        It 'Should support token-based authentication for CI/CD scenarios' {
            InModuleScope K.PSGallery.PackageRepoProvider {
                # Test constants
                $TestRepoName = "TestRepo"
                $TestProviderName = "GitHub"
                $TestNupkgPath = Join-Path ([System.IO.Path]::GetTempPath()) "TestModule.1.0.0.nupkg"
                
                # Mock provider resolution and loading
                Mock Get-RegisteredRepoProvider { return $TestProviderName }
                Mock Get-RepoProvider { 
                    return [PSCustomObject]@{ Name = $TestProviderName }
                }
                Mock Resolve-ModulePath { return $PWD.Path }
                
                # Mock Compress-PSResource to avoid actual compression
                Mock Compress-PSResource { }
                
                # Mock Get-ChildItem to return a fake .nupkg file
                Mock Get-ChildItem {
                    return [PSCustomObject]@{
                        FullName = $TestNupkgPath
                        Length = 1024
                    }
                } -ParameterFilter { $Filter -eq '*.nupkg' }
                
                # Create and mock the provider's Invoke-Publish function
                if (-not (Get-Command -Name 'GitHub\Invoke-Publish' -ErrorAction SilentlyContinue)) {
                    New-Item -Path Function:\ -Name 'GitHub\Invoke-Publish' -Value {
                        param($RepositoryName, $NupkgPath, $Credential)
                    } -Force
                }
                Mock GitHub\Invoke-Publish { }
                
                $params = @{
                    RepositoryName = $TestRepoName
                    Token = 'ghp_test123token'
                }
                
                { Publish-Package @params } | Should -Not -Throw
                
                # Verify the provider was called with a credential (token converted to PSCredential)
                Should -Invoke GitHub\Invoke-Publish -Times 1
            }
        }
    }
}
