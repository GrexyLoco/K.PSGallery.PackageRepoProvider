<#
.SYNOPSIS
    Write GitHub Actions error summary.

.DESCRIPTION
    Generates a formatted error summary for GitHub Actions UI with diagnostics.

.PARAMETER Context
    Publish context object with error details
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [PSCustomObject]$Context
)

$errorSummary = @"
## ❌ Publish Failed

**Error:** ``$($Context.Error)``

### 🔍 Diagnostics

| Property | Value |
|----------|-------|
| 🎯 Repository | ``$($Context.Repository)`` |
| 🔗 Registry | ``$($Context.RegistryUri)`` |
| 🔄 Load Mode | $($Context.LoadMode) |
| 🔑 Auth Token | $(if ($Context.TokenPresent) { '✅ Present' } else { '❌ Missing' }) |

### 💡 Common Issues

- Check ``GITHUB_TOKEN`` has ``packages:write`` permission
- Verify module manifest is valid: ``Test-ModuleManifest``
- Ensure ``PSResourceGet`` is installed: ``Get-Module PSResourceGet -ListAvailable``
- Check repository registration: ``Get-PSResourceRepository``
- Review [PSResourceGet Documentation](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/)

### 📋 Troubleshooting Steps

1. **Verify PSResourceGet version:**
   ``````powershell
   Get-Module Microsoft.PowerShell.PSResourceGet -ListAvailable | Select-Object Version
   ``````

2. **Check registered repositories:**
   ``````powershell
   Get-PSResourceRepository
   ``````

3. **Validate manifest:**
   ``````powershell
   Test-ModuleManifest -Path ./K.PSGallery.PackageRepoProvider.psd1
   ``````
"@

$errorSummary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8
Write-Information "📊 Error summary written to GitHub Actions UI"
