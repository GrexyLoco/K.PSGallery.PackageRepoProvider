function Resolve-ModulePath {
    <#
    .SYNOPSIS
        Resolves the module path through smart auto-discovery.
    
    .DESCRIPTION
        Searches for PowerShell module manifest files (.psd1) in the current directory.
        Uses intelligent filtering to distinguish between module manifests and configuration files.
        
        Smart Discovery Logic:
        1. Find all .psd1 files in current directory
        2. Validate each file is a real PowerShell module manifest (has RootModule or ModuleVersion)
        3. Exclude configuration files (PSScriptAnalyzerSettings.psd1, etc.)
        
        Returns the directory containing the found manifest.
        Throws an error if multiple valid module manifests or no manifests are found.
    
    .PARAMETER AutoDiscovery
        Enables auto-discovery mode.
    
    .EXAMPLE
        Resolve-ModulePath -AutoDiscovery
        Returns: Path to directory containing the valid module manifest
        
    .NOTES
        This function distinguishes between:
        - Module Manifests: Have RootModule and/or ModuleVersion keys
        - Config Files: PSScriptAnalyzerSettings.psd1, build configs, etc.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [switch]$AutoDiscovery
    )
    
    if (-not $AutoDiscovery) {
        throw "AutoDiscovery switch is required"
    }
    
    $currentLocation = Get-Location
    
    # Search for all .psd1 files in current directory
    $allPsd1Files = Get-ChildItem -Path $currentLocation -Filter '*.psd1' -File -ErrorAction SilentlyContinue
    
    if ($allPsd1Files.Count -eq 0) {
        throw "No module manifest found in current directory: $currentLocation"
    }
    
    Write-SafeDebugLog -Message "Found $($allPsd1Files.Count) .psd1 file(s), validating module manifests..." -Additional @{
        Location = $currentLocation.ToString()
        Files = ($allPsd1Files | ForEach-Object { $_.Name }) -join ', '
    }
    
    # Smart Discovery: Validate each .psd1 is a real module manifest
    $validManifests = $allPsd1Files | Where-Object {
        try {
            $data = Import-PowerShellDataFile $_.FullName -ErrorAction Stop
            
            # Real PowerShell modules MUST have either RootModule or ModuleVersion
            $isValidManifest = $data.ContainsKey('RootModule') -or $data.ContainsKey('ModuleVersion')
            
            if ($isValidManifest) {
                Write-SafeDebugLog -Message "Valid module manifest: $($_.Name)" -Additional @{
                    File = $_.Name
                    HasRootModule = $data.ContainsKey('RootModule')
                    HasModuleVersion = $data.ContainsKey('ModuleVersion')
                }
            } else {
                Write-SafeDebugLog -Message "Skipping non-module .psd1: $($_.Name)" -Additional @{
                    File = $_.Name
                    Reason = 'Missing RootModule and ModuleVersion keys'
                }
            }
            
            return $isValidManifest
        }
        catch {
            Write-SafeDebugLog -Message "Skipping invalid .psd1: $($_.Name)" -Additional @{
                File = $_.Name
                Error = $_.Exception.Message
            }
            return $false
        }
    }
    
    # No valid module manifests found
    if ($validManifests.Count -eq 0) {
        $allFiles = ($allPsd1Files | ForEach-Object { $_.Name }) -join ', '
        throw "No valid PowerShell module manifest (.psd1) found in current directory: $currentLocation. Found .psd1 files: $allFiles (none are valid module manifests)"
    }
    
    # Multiple valid module manifests found
    if ($validManifests.Count -gt 1) {
        $fileList = ($validManifests | ForEach-Object { $_.Name }) -join ', '
        throw "Multiple valid module manifests found in current directory. Please specify ModulePath explicitly. Found: $fileList"
    }
    
    # Success: Exactly one valid module manifest found
    $foundManifest = $validManifests[0]
    Write-SafeDebugLog -Message "Module manifest resolved successfully" -Additional @{
        Manifest = $foundManifest.Name
        Path = $foundManifest.DirectoryName
    }
    
    # Return the directory containing the manifest
    return $foundManifest.DirectoryName
}
