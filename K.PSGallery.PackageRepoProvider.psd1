@{
    RootModule = 'K.PSGallery.PackageRepoProvider.psm1'
    ModuleVersion = '1.0.2'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID = 'f8d2c4a6-9b3e-4f1a-8d5c-7e2b9a4f6c8d'
    Author = '1d70f'
    CompanyName = '1d70f'
    Copyright = '(c) 2025 1d70f. All rights reserved.'
    Description = 'Aggregator/Facade module for private package repositories with automatic provider routing. Supports GitHub Packages and GitLab Package Registry with pluggable provider architecture.'
    PowerShellVersion = '7.0'
    RequiredModules = @()
    RequiredAssemblies = @()
    ScriptsToProcess = @('Private/SafeLogging.ps1')
    TypesToProcess = @()
    FormatsToProcess = @()
    NestedModules = @()
    FunctionsToExport = @(
        'Register-PackageRepo',
        'Publish-Package',
        'Install-PackageModule',
        'Import-PackageModule',
        'Remove-PackageRepo',
        'Get-PackageRepoProvider'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'PackageManagement', 'NuGet', 'GitHub', 'GitLab', 'PSGallery', 'Provider', 'Packages')
            LicenseUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider/blob/main/LICENSE'
            ProjectUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider'
            ReleaseNotes = @'
## Version 1.0.0
- Initial release with provider routing and public API
- Support for GitHub Packages and GitLab Package Registry
- Pluggable provider architecture for extensibility
'@
        }
    }
    HelpInfoURI = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider/blob/main/README.md'
}
