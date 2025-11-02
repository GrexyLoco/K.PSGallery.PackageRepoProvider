BeforeAll {
    # Import the function
    . $PSScriptRoot/../../Private/Resolve-ModulePath.ps1
    # Import SafeLogging for logging within tests
    . $PSScriptRoot/../../Private/SafeLogging.ps1
}

Describe 'Resolve-ModulePath' {
    Context 'Auto-Discovery' {
        BeforeEach {
            # Create a temporary directory for testing
            $testDir = New-Item -ItemType Directory -Path (Join-Path $TestDrive "TestModule-$(Get-Random)")
            Push-Location $testDir
        }
        
        AfterEach {
            Pop-Location
        }
        
        It 'Should find single .psd1 file' {
            New-Item -ItemType File -Path (Join-Path $testDir 'TestModule.psd1')
            # and fill psd1 with minimal content rootmodule and version
            Set-Content -Path (Join-Path $testDir 'TestModule.psd1') -Value @"
@{
    RootModule = 'TestModule.psm1'
    ModuleVersion = '1.0.0'
}
"@
            
            $result = Resolve-ModulePath -AutoDiscovery
            $result | Should -Be $testDir.FullName
        }
        
        It 'Should throw when no .psd1 files found' {
            { Resolve-ModulePath -AutoDiscovery } | Should -Throw -ExpectedMessage '*No module manifest*'
        }
        
        It 'Should throw when multiple .psd1 files found' {
            New-Item -ItemType File -Path (Join-Path $testDir 'Module1.psd1')
            Set-Content -Path (Join-Path $testDir 'Module1.psd1') -Value @"
@{
    RootModule = 'Module1.psm1'
    ModuleVersion = '1.0.0'
}
"@

            New-Item -ItemType File -Path (Join-Path $testDir 'Module2.psd1')
            Set-Content -Path (Join-Path $testDir 'Module2.psd1') -Value @"
@{
    RootModule = 'Module2.psm1'
    ModuleVersion = '1.0.1'
}
"@

            
            { Resolve-ModulePath -AutoDiscovery } | Should -Throw -ExpectedMessage '*Multiple valid module manifests*'
        }
        
        It 'Should throw when AutoDiscovery switch is not provided' {
            { Resolve-ModulePath } | Should -Throw -ExpectedMessage '*AutoDiscovery switch is required*'
        }
    }
}
