<#
.SYNOPSIS
    Finds and validates a PowerShell module manifest file.

.DESCRIPTION
    Locates the module manifest (.psd1) file for a given module with robust validation.
    Implements a hybrid approach:
    1. Preferred: Searches for exact match "<ModuleName>.psd1"
    2. Fallback: Searches for any "*.psd1" file with warning
    3. Validates the manifest contains expected module metadata

.PARAMETER ModuleName
    The name of the module to find the manifest for.

.PARAMETER SearchPath
    The directory path to search in. Defaults to current directory.

.PARAMETER Strict
    If specified, only accepts exact match "<ModuleName>.psd1" and fails on multiple .psd1 files.

.OUTPUTS
    PSCustomObject with properties:
    - ManifestPath: Full path to the manifest file (or $null if not found)
    - IsValid: Boolean indicating if manifest passed validation
    - ValidationMethod: String indicating how manifest was found (Exact, Fallback, or NotFound)
    - Warnings: Array of warning messages
    - Errors: Array of error messages

.EXAMPLE
    $result = .\Find-ModuleManifest.ps1 -ModuleName "MyModule"
    if ($result.IsValid) {
        Write-Host "Found manifest: $($result.ManifestPath)"
    }

.EXAMPLE
    $result = .\Find-ModuleManifest.ps1 -ModuleName "MyModule" -Strict
    # Will fail if multiple .psd1 files exist or name doesn't match exactly
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,

    [Parameter(Mandatory = $false)]
    [string]$SearchPath = '.',

    [Parameter(Mandatory = $false)]
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

# Initialize result object
$result = [PSCustomObject]@{
    ManifestPath     = $null
    IsValid          = $false
    ValidationMethod = 'NotFound'
    Warnings         = @()
    Errors           = @()
}

Write-Verbose "Searching for module manifest in: $SearchPath"
Write-Verbose "Module name: $ModuleName"

# Step 1: Try exact match "<ModuleName>.psd1"
$exactManifestPath = Join-Path $SearchPath "$ModuleName.psd1"
$exactManifestExists = Test-Path $exactManifestPath

if ($exactManifestExists) {
    Write-Verbose "Found exact match: $exactManifestPath"
    $result.ManifestPath = (Get-Item $exactManifestPath).FullName
    $result.ValidationMethod = 'Exact'
} else {
    Write-Verbose "Exact match not found. Searching for any *.psd1 files..."
    
    # Step 2: Fallback to any *.psd1 file
    $allManifests = Get-ChildItem -Path $SearchPath -Filter '*.psd1' -File -ErrorAction SilentlyContinue
    
    if ($allManifests.Count -eq 0) {
        $result.Errors += "No .psd1 files found in: $SearchPath"
        Write-Error "No module manifest files found in $SearchPath"
        return $result
    }
    
    if ($allManifests.Count -gt 1) {
        $manifestList = ($allManifests.Name | ForEach-Object { "  - $_" }) -join "`n"
        $warningMsg = "Multiple .psd1 files found in $SearchPath`:`n$manifestList"
        $result.Warnings += $warningMsg
        
        if ($Strict) {
            $result.Errors += "Strict mode: Multiple .psd1 files found but expected exactly one named '$ModuleName.psd1'"
            Write-Error $result.Errors[-1]
            return $result
        }
        
        Write-Warning $warningMsg
        Write-Warning "Using first file: $($allManifests[0].Name)"
    }
    
    $result.ManifestPath = $allManifests[0].FullName
    $result.ValidationMethod = 'Fallback'
    
    if (-not $Strict) {
        $result.Warnings += "Using fallback manifest discovery (not exact match): $($allManifests[0].Name)"
    }
}

# Step 3: Validate the manifest file
Write-Verbose "Validating manifest: $($result.ManifestPath)"

try {
    # Test if it's a valid PowerShell data file
    $manifestData = Test-ModuleManifest -Path $result.ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue
    
    # Check for essential module properties
    $hasModuleVersion = $null -ne $manifestData.ModuleVersion
    $hasRootModule = -not [string]::IsNullOrWhiteSpace($manifestData.RootModule)
    $hasGuid = $null -ne $manifestData.Guid
    
    if (-not $hasModuleVersion) {
        $result.Errors += "Manifest missing ModuleVersion"
    }
    
    if (-not $hasRootModule) {
        $result.Warnings += "Manifest missing RootModule (may be a manifest-only module)"
    }
    
    if (-not $hasGuid) {
        $result.Warnings += "Manifest missing GUID"
    }
    
    # Check if module name matches (if we used fallback discovery)
    if ($result.ValidationMethod -eq 'Fallback' -and $manifestData.Name -ne $ModuleName) {
        $warnMsg = "Manifest module name '$($manifestData.Name)' does not match expected name '$ModuleName'"
        $result.Warnings += $warnMsg
        
        if ($Strict) {
            $result.Errors += "Strict mode: $warnMsg"
            $result.IsValid = $false
            Write-Error $result.Errors[-1]
            return $result
        }
        
        Write-Warning $warnMsg
    }
    
    # If no errors, mark as valid
    $result.IsValid = $result.Errors.Count -eq 0
    
    Write-Verbose "Manifest validation complete. Valid: $($result.IsValid)"
    
} catch {
    $result.Errors += "Manifest validation failed: $($_.Exception.Message)"
    $result.IsValid = $false
    Write-Error "Failed to validate manifest: $($_.Exception.Message)"
}

# Output warnings if any
foreach ($warning in $result.Warnings) {
    Write-Warning $warning
}

return $result
