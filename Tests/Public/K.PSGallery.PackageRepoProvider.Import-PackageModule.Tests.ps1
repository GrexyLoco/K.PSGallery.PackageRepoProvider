BeforeAll {
    # Import the function
    . $PSScriptRoot/../../Public/Import-PackageModule.ps1
}

Describe 'Import-PackageModule' {
    Context 'Parameter Sets' {
        It 'Should import by module name' {
            Mock Import-Module { }
            
            Import-PackageModule -ModuleName 'TestModule'
            
            Should -Invoke Import-Module -Times 1 -ParameterFilter {
                $Name -eq 'TestModule'
            }
        }
        
        It 'Should import by module path' {
            Mock Import-Module { }
            Mock Test-Path { return $true }
            
            Import-PackageModule -ModulePath '/test/path' 
            
            Should -Invoke Import-Module -Times 1 -ParameterFilter {
                $Name -eq '/test/path'
            }
        }
        
        It 'Should pass Force parameter' {
            Mock Import-Module { }
            
            Import-PackageModule -ModuleName 'TestModule' -Force
            
            Should -Invoke Import-Module -Times 1 -ParameterFilter {
                $Force -eq $true
            }
        }
        
        It 'Should pass PassThru parameter' {
            Mock Import-Module { }
            
            Import-PackageModule -ModuleName 'TestModule' -PassThru
            
            Should -Invoke Import-Module -Times 1 -ParameterFilter {
                $PassThru -eq $true
            }
        }
    }
}
