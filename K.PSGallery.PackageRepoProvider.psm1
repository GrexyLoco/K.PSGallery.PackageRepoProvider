# K.PSGallery.PackageRepoProvider Module
# Aggregator/Facade for private package repositories

# Try to import LoggingModule (non-blocking)
$script:LoggingModuleAvailable = $false
try {
    Import-Module K.PSGallery.LoggingModule -ErrorAction Stop
    $script:LoggingModuleAvailable = $true
}
catch {
    # Fallback to standard cmdlets - no error
    $script:LoggingModuleAvailable = $false
}

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Note: Function exports are defined in the module manifest (.psd1) via FunctionsToExport
