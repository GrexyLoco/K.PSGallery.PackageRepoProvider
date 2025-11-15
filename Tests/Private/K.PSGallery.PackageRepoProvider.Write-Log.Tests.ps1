BeforeAll {
    # Set LoggingModuleAvailable to false to test fallback behavior
    $script:LoggingModuleAvailable = $false
    
    # Manually dot-source the Write-Log.ps1 script
    $scriptPath = Join-Path $PSScriptRoot '../../Private/Write-Log.ps1'
    . $scriptPath
}

Describe 'Write-Log Functions' {
    Context 'When K.PSGallery.LoggingModule is NOT available' {
        It 'Write-LogInfo should fallback to Write-Output' {
            # Capture standard output
            $output = Write-LogInfo 'Test info message'
            $output | Should -Be '[INFO] Test info message'
        }

        It 'Write-LogDebug should fallback to Write-Verbose' {
            # Capture verbose output
            $output = Write-LogDebug @{ Key = 'Value' } -Verbose 4>&1
            $output | Should -Match 'Key.*Value'
        }

        It 'Write-LogWarning should fallback to Write-Warning' {
            # Capture warning output
            $output = Write-LogWarning 'Test warning' 3>&1
            $output | Should -Match 'Test warning'
        }

        It 'Write-LogError should fallback to Write-Error' {
            # Capture error output
            $output = Write-LogError 'Test error' 2>&1
            # Error messages contain the text
            $output.Exception.Message | Should -Match 'Test error'
        }
    }

    Context 'Function Availability' {
        It 'Write-LogInfo should be defined' {
            Get-Command Write-LogInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Write-LogDebug should be defined' {
            Get-Command Write-LogDebug -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Write-LogWarning should be defined' {
            Get-Command Write-LogWarning -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Write-LogError should be defined' {
            Get-Command Write-LogError -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter Validation' {
        It 'Write-LogInfo should accept string message parameter' {
            { Write-LogInfo -Message 'Test' | Out-Null } | Should -Not -Throw
        }

        It 'Write-LogDebug should accept object data parameter' {
            { Write-LogDebug -Data @{ Key = 'Value' } 4>$null } | Should -Not -Throw
        }

        It 'Write-LogWarning should accept string message parameter' {
            { Write-LogWarning -Message 'Test' 3>$null } | Should -Not -Throw
        }

        It 'Write-LogError should accept string message parameter' {
            { Write-LogError -Message 'Test' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
