function Import-PackageModule {
    <#
    .SYNOPSIS
        Imports a PowerShell module.
    
    .DESCRIPTION
        Wrapper around Import-Module with support for both name-based and path-based imports.
        Designed to be used after Install-Package.
    
    .PARAMETER ModuleName
        The name of the module to import.
    
    .PARAMETER ModulePath
        The path to the module to import.
    
    .PARAMETER Force
        Forces import even if the module is already loaded.
    
    .PARAMETER PassThru
        Returns the module object after import.
    
    .EXAMPLE
        Import-PackageModule -ModuleName 'MyModule'
        
        Imports MyModule by name.
    
    .EXAMPLE
        Import-PackageModule -ModulePath './MyModule' -Force
        
        Imports a module from a specific path, forcing reload.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory)]
        [Parameter(ParameterSetName = 'ByPath')]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(ParameterSetName = 'ByPath', Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ModulePath,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )
    
    # Build Import-Module parameters
    $importParams = @{}
    
    if ($ModuleName -and -not $ModulePath) {
        $importParams['Name'] = $ModuleName
    }
    
    if ($ModulePath) {
        $importParams['Name'] = $ModulePath
    }
    
    if ($Force) {
        $importParams['Force'] = $true
    }
    
    if ($PassThru) {
        $importParams['PassThru'] = $true
    }
    
    # Import the module
    Import-Module @importParams
}
