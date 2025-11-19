<#
.SYNOPSIS
    Run PSScriptAnalyzer on production code.

.DESCRIPTION
    Validates PowerShell code quality using PSScriptAnalyzer.
    Scans Public and Private folders, excludes test files and trailing whitespace warnings.

.PARAMETER Paths
    Paths to scan (default: Public, Private folders)

.PARAMETER ExcludeRules
    PSScriptAnalyzer rules to exclude
#>
[CmdletBinding()]
param(
    [string[]]$Paths = @('./Public', './Private'),
    
    [string[]]$ExcludeRules = @('PSAvoidTrailingWhitespace', 'PSReviewUnusedParameter')
)

$ErrorActionPreference = 'Stop'

Write-Host "📋 Running PSScriptAnalyzer..."
Write-Host ""

# Install PSScriptAnalyzer
Install-PSResource -Name PSScriptAnalyzer `
    -Scope CurrentUser `
    -TrustRepository `
    -SkipDependencyCheck `
    -Verbose

Write-Host ""
Write-Host "🔍 Scanning paths:"
$Paths | ForEach-Object { Write-Host "   - $_" }

# Scan production code (exclude tests)
$results = $Paths | ForEach-Object { 
    Invoke-ScriptAnalyzer -Path $_ `
        -Recurse `
        -Severity Error,Warning `
        -ExcludeRule $ExcludeRules
}

if ($results) {
    Write-Host ""
    Write-Host "❌ PSScriptAnalyzer found $($results.Count) issues:"
    Write-Host ""
    $results | Format-Table -Property RuleName, Severity, ScriptName, Line -AutoSize
    throw "PSScriptAnalyzer validation failed"
}

Write-Host ""
Write-Host "✅ PSScriptAnalyzer passed! No issues found."
