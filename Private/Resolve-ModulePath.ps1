function Resolve-ModulePath {
    <#
    .SYNOPSIS
        Resolves the module path through auto-discovery.
    
    .DESCRIPTION
        Searches for .psd1 manifest files in the current directory.
        Returns the directory containing the first found manifest.
        Throws an error if multiple manifests or no manifests are found.
    
    .PARAMETER AutoDiscovery
        Enables auto-discovery mode.
    
    .EXAMPLE
        Resolve-ModulePath -AutoDiscovery
        Returns: Path to directory containing the .psd1 file
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
    
    # Search for .psd1 files in current directory
    $manifestFiles = Get-ChildItem -Path (Get-Location) -Filter '*.psd1' -File -ErrorAction SilentlyContinue
    
    if ($manifestFiles.Count -eq 0) {
        throw "No module manifest (.psd1) found in current directory: $(Get-Location)"
    }
    
    if ($manifestFiles.Count -gt 1) {
        $fileList = ($manifestFiles | ForEach-Object { $_.Name }) -join ', '
        throw "Multiple module manifests found in current directory. Please specify ModulePath explicitly. Found: $fileList"
    }
    
    # Return the directory containing the manifest
    return $manifestFiles[0].DirectoryName
}
