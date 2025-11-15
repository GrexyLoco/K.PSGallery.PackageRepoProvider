<#
.SYNOPSIS
    Logging wrapper with fallback to standard PowerShell cmdlets.

.DESCRIPTION
    Tries to use K.PSGallery.LoggingModule if available.
    Falls back to Write-Host/Write-Verbose/Write-Warning/Write-Error if not.
    
    This module is loaded once at module import time via ScriptsToProcess in the manifest.
    The logging module availability is checked once and cached in a script-scoped variable.
#>

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

<#
.SYNOPSIS
    Writes an informational log message.

.PARAMETER Message
    The message to log.

.EXAMPLE
    Write-LogInfo "Repository registered successfully"
#>
function Write-LogInfo {
    [CmdletBinding()]
    param([string]$Message)
    
    if ($script:LoggingModuleAvailable) {
        K.PSGallery.LoggingModule\Write-LogInfo -Message $Message
    }
    else {
        Write-Host "[INFO] $Message" -ForegroundColor Cyan
    }
}

<#
.SYNOPSIS
    Writes a debug log message.

.PARAMETER Data
    The data to log (typically a hashtable with debug information).

.EXAMPLE
    Write-LogDebug @{ Repository = "MyRepo"; Provider = "GitHub" }
#>
function Write-LogDebug {
    [CmdletBinding()]
    param([object]$Data)
    
    if ($script:LoggingModuleAvailable) {
        K.PSGallery.LoggingModule\Write-LogDebug -Data $Data
    }
    else {
        Write-Verbose ($Data | ConvertTo-Json -Compress)
    }
}

<#
.SYNOPSIS
    Writes a warning log message.

.PARAMETER Message
    The warning message to log.

.EXAMPLE
    Write-LogWarning "Repository not found"
#>
function Write-LogWarning {
    [CmdletBinding()]
    param([string]$Message)
    
    if ($script:LoggingModuleAvailable) {
        K.PSGallery.LoggingModule\Write-LogWarning -Message $Message
    }
    else {
        Write-Warning $Message
    }
}

<#
.SYNOPSIS
    Writes an error log message.

.PARAMETER Message
    The error message to log.

.EXAMPLE
    Write-LogError "Failed to register repository"
#>
function Write-LogError {
    [CmdletBinding()]
    param([string]$Message)
    
    if ($script:LoggingModuleAvailable) {
        K.PSGallery.LoggingModule\Write-LogError -Message $Message
    }
    else {
        Write-Error $Message
    }
}
