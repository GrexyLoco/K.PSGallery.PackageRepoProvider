@{
    RootModule = 'K.PSGallery.PackageRepoProvider.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'GrexyLoco'
    CompanyName = 'GrexyLoco'
    Copyright = '(c) 2025 GrexyLoco. All rights reserved.'
    Description = 'Aggregator/Facade module for private package repositories with automatic provider routing (GitHub, GitLab)'
    PowerShellVersion = '7.0'
    
    # RequiredModules = @(
    #     @{
    #         ModuleName = 'K.PSGallery.LoggingModule'
    #         ModuleVersion = '0.1.0'
    #     }
    # )
    
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
            Tags = @('PowerShell', 'PackageManagement', 'NuGet', 'GitHub', 'GitLab', 'PSGallery')
            LicenseUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider/blob/main/LICENSE'
            ProjectUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider'
            ReleaseNotes = 'Initial release with provider routing and public API'
        }
    }
}
