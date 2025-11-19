<#
.SYNOPSIS
    Run Pester tests with specified configuration.

.DESCRIPTION
    Fallback script for running Pester tests until K.Actions.PesterTestDiscovery is available.
    Installs Pester, runs tests, and outputs results.

.PARAMETER Path
    Path to test directory or specific test file.

.PARAMETER Output
    Output verbosity level (None, Normal, Detailed, Diagnostic).

.EXAMPLE
    Test-PesterTests.ps1 -Path './Tests/Private/' -Output 'Detailed'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = './Tests/Private/',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Output = 'Detailed'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    Write-Information "🧪 Installing Pester..."
    Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository -SkipDependencyCheck -Verbose
    
    Write-Information ""
    Write-Information "🧪 Running Pester tests..."
    Write-Information "   Path: $Path"
    Write-Information "   Output: $Output"
    Write-Information ""
    
    # Run Pester tests
    $config = New-PesterConfiguration
    $config.Run.Path = $Path
    $config.Output.Verbosity = $Output
    $config.TestResult.Enabled = $true
    
    $result = Invoke-Pester -Configuration $config
    
    # Check results
    if ($result.FailedCount -gt 0) {
        Write-Information ""
        Write-Error "❌ Pester tests FAILED - Failed: $($result.FailedCount), Passed: $($result.PassedCount)"
        throw "Pester tests failed with $($result.FailedCount) failures"
    }
    
    Write-Information ""
    Write-Information "✅ All Pester tests passed!"
    Write-Information "   Passed: $($result.PassedCount)"
}
catch {
    Write-Information ""
    Write-Error "❌ Test execution failed: $($_.Exception.Message)"
    throw
}
