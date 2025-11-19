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

try {
    Write-Host "🧪 Installing Pester..."
    Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository -SkipDependencyCheck -Verbose
    
    Write-Host ""
    Write-Host "🧪 Running Pester tests..."
    Write-Host "   Path: $Path"
    Write-Host "   Output: $Output"
    Write-Host ""
    
    # Run Pester tests
    $config = New-PesterConfiguration
    $config.Run.Path = $Path
    $config.Output.Verbosity = $Output
    $config.TestResult.Enabled = $true
    
    $result = Invoke-Pester -Configuration $config
    
    # Check results
    if ($result.FailedCount -gt 0) {
        Write-Host ""
        Write-Host "❌ Pester tests FAILED" -ForegroundColor Red
        Write-Host "   Failed: $($result.FailedCount)" -ForegroundColor Red
        Write-Host "   Passed: $($result.PassedCount)" -ForegroundColor Green
        throw "Pester tests failed with $($result.FailedCount) failures"
    }
    
    Write-Host ""
    Write-Host "✅ All Pester tests passed!" -ForegroundColor Green
    Write-Host "   Passed: $($result.PassedCount)" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
