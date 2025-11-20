<#
.SYNOPSIS
    Run Pester tests with specified configuration.

.DESCRIPTION
    Uses K.PSGallery.PesterTestDiscovery for intelligent test discovery.
    Falls back to manual Pester execution if discovery module is not available.
    
    TODO: Change to load K.PSGallery.PesterTestDiscovery from GitHub Packages 
    after the module is published to the package feed.

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

#region Helper Functions

function Import-PesterTestDiscovery {
    [CmdletBinding()]
    param()
    
    # TODO: Load from GitHub Packages when published
    Write-Information "📦 Loading K.PSGallery.PesterTestDiscovery (LOCAL for initial release)..."
    Write-Information "   ⚠️  TODO: Migrate to GitHub Packages when published"
    
    $discoveryPath = '../K.PSGallery.PesterTestDiscovery/K.PSGallery.PesterTestDiscovery.psd1'
    
    if (Test-Path $discoveryPath) {
        try {
            Import-Module $discoveryPath -Force -Verbose
            Write-Information "✅ PesterTestDiscovery loaded from local path"
            return $true
        }
        catch {
            Write-Information "⚠️  Failed to import PesterTestDiscovery: $($_.Exception.Message)"
            return $false
        }
    }
    else {
        Write-Information "⚠️  PesterTestDiscovery not found at: $discoveryPath"
        return $false
    }
}

function Install-Pester {
    [CmdletBinding()]
    param()
    
    Write-Information "🧪 Installing Pester..."
    Install-PSResource -Name Pester -Scope CurrentUser -TrustRepository -SkipDependencyCheck -Verbose
}

function Invoke-PesterWithDiscovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Output
    )
    
    Write-Information "🔍 Using PesterTestDiscovery for intelligent test discovery..."
    
    # Use PesterTestDiscovery to find test files
    $testFiles = Invoke-TestDiscovery -RootPath $Path
    
    if ($testFiles.Count -eq 0) {
        Write-Information "⚠️  No test files found by PesterTestDiscovery"
        return Invoke-PesterManual -Path $Path -Output $Output
    }
    
    Write-Information "   Found $($testFiles.Count) test file(s)"
    
    # Run Pester with discovered files
    $config = New-PesterConfiguration
    $config.Run.Path = $testFiles
    $config.Output.Verbosity = $Output
    $config.TestResult.Enabled = $true
    
    return Invoke-Pester -Configuration $config
}

function Invoke-PesterManual {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Output
    )
    
    Write-Information "🧪 Running Pester tests (manual discovery)..."
    Write-Information "   Path: $Path"
    Write-Information "   Output: $Output"
    
    # Run Pester tests
    $config = New-PesterConfiguration
    $config.Run.Path = $Path
    $config.Output.Verbosity = $Output
    $config.TestResult.Enabled = $true
    
    return Invoke-Pester -Configuration $config
}

#endregion

try {
    # Install Pester
    Install-Pester
    
    Write-Information ""
    
    # Try to use PesterTestDiscovery
    $useDiscovery = Import-PesterTestDiscovery
    
    Write-Information ""
    Write-Information "🧪 Running Pester tests..."
    Write-Information ""
    
    # Run tests
    if ($useDiscovery) {
        $result = Invoke-PesterWithDiscovery -Path $Path -Output $Output
    }
    else {
        $result = Invoke-PesterManual -Path $Path -Output $Output
    }
    
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
