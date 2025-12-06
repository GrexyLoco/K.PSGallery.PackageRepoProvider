<#
.SYNOPSIS
    Publishes PowerShell module to GitHub Packages via K.PSGallery.PackageRepoProvider.

.DESCRIPTION
    Installs K.PSGallery.PackageRepoProvider from GitHub Packages and uses it for
    intelligent package publishing. Falls back to built-in Publish-PSResource
    if provider module installation fails.

.PARAMETER ModuleName
    Name of the PowerShell module to publish.

.PARAMETER NewVersion
    Version to publish (used for verification).

.PARAMETER GitHubToken
    GitHub token for package publishing authentication.

.PARAMETER RepositoryOwner
    GitHub repository owner (e.g., 'GrexyLoco').

.OUTPUTS
    Writes publish summary to GITHUB_STEP_SUMMARY.
    Sets GITHUB_OUTPUT variable: package-published (true/false)

.EXAMPLE
    ./Publish-Package.ps1 -ModuleName "MyModule" -NewVersion "1.2.3" -GitHubToken $env:GITHUB_TOKEN -RepositoryOwner "GrexyLoco"

.NOTES
    Platform-independent script for GitHub Actions workflows.
    Installs K.PSGallery.PackageRepoProvider from GitHub Packages, then uses it to publish.
    Handles repository registration, package publishing, and cleanup.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory = $true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory = $true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory = $true)]
    [string]$RepositoryOwner,
    
    # 🔧 DEBUG: Set to $true to enable detailed diagnostics (remove after debugging)
    [Parameter()]
    [switch]$DebugMode = $false
)

# ═══════════════════════════════════════════════════════════════════════════
# 🐛 DEBUG FUNCTIONS (set $DebugMode = $true to enable)
# ═══════════════════════════════════════════════════════════════════════════
function Write-DebugInfo {
    param([string]$Message)
    if ($DebugMode) {
        Write-Output "🐛 DEBUG: $Message"
        Write-Output "🐛 $Message" >> $env:GITHUB_STEP_SUMMARY
    }
}

function Show-ManifestDebugInfo {
    param([string]$Path, [string]$Context)
    if (-not $DebugMode) { return }
    
    Write-Output ""
    Write-Output "═══════════════════════════════════════════════════════════════"
    Write-Output "🐛 DEBUG: Manifest Analysis - $Context"
    Write-Output "═══════════════════════════════════════════════════════════════"
    Write-Output "📁 Path: $Path"
    Write-Output "📁 Exists: $(Test-Path $Path)"
    Write-Output "📁 Working Dir: $(Get-Location)"
    Write-Output ""
    
    # List directory contents
    Write-Output "📂 Directory Contents:"
    Get-ChildItem -Path (Split-Path $Path -Parent -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue | 
        ForEach-Object { Write-Output "   - $($_.Name)" }
    Write-Output ""
    
    # Find all PSD1 files
    Write-Output "📋 All PSD1 files in current directory:"
    Get-ChildItem -Path '.' -Filter '*.psd1' -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
        ForEach-Object { Write-Output "   - $($_.FullName)" }
    Write-Output ""
    
    # Try to read manifest
    $psd1File = Get-ChildItem -Path $Path -Filter '*.psd1' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $psd1File) {
        $psd1File = Get-Item "$Path.psd1" -ErrorAction SilentlyContinue
    }
    if (-not $psd1File -and (Test-Path $Path)) {
        $psd1File = Get-ChildItem -Path $Path -Filter '*.psd1' -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    
    if ($psd1File) {
        Write-Output "📄 Found Manifest: $($psd1File.FullName)"
        try {
            $manifest = Test-ModuleManifest -Path $psd1File.FullName -ErrorAction Stop
            Write-Output "   ✅ Author: '$($manifest.Author)'"
            Write-Output "   ✅ Version: '$($manifest.Version)'"
            Write-Output "   ✅ Description: '$($manifest.Description.Substring(0, [Math]::Min(50, $manifest.Description.Length)))...'"
            Write-Output "   ✅ RootModule: '$($manifest.RootModule)'"
        }
        catch {
            Write-Output "   ❌ Test-ModuleManifest failed: $($_.Exception.Message)"
            Write-Output "   📝 Raw content (first 20 lines):"
            Get-Content $psd1File.FullName -TotalCount 20 | ForEach-Object { Write-Output "      $_" }
        }
    }
    else {
        Write-Output "❌ No PSD1 file found at: $Path"
    }
    Write-Output ""
}

function Show-InstalledModuleDebugInfo {
    param([string]$ModuleName)
    if (-not $DebugMode) { return }
    
    Write-Output ""
    Write-Output "═══════════════════════════════════════════════════════════════"
    Write-Output "🐛 DEBUG: Installed Module Check - $ModuleName"
    Write-Output "═══════════════════════════════════════════════════════════════"
    
    Write-Output "📁 PSModulePath:"
    $env:PSModulePath -split [IO.Path]::PathSeparator | ForEach-Object { Write-Output "   - $_" }
    Write-Output ""
    
    $installedModule = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
    if ($installedModule) {
        Write-Output "✅ Module found in module path:"
        $installedModule | ForEach-Object {
            Write-Output "   - Version: $($_.Version)"
            Write-Output "   - Path: $($_.ModuleBase)"
            $manifestPath = Join-Path $_.ModuleBase "$ModuleName.psd1"
            if (Test-Path $manifestPath) {
                try {
                    $m = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
                    Write-Output "   - Author in installed: '$($m.Author)'"
                }
                catch {
                    Write-Output "   - ❌ Manifest error: $($_.Exception.Message)"
                }
            }
        }
    }
    else {
        Write-Output "❌ Module not found in any PSModulePath"
    }
    Write-Output ""
}

# ═══════════════════════════════════════════════════════════════════════════
# 📋 Summary Header
# ═══════════════════════════════════════════════════════════════════════════
Write-Output "## 📦 Package Publishing" >> $env:GITHUB_STEP_SUMMARY
Write-Output "" >> $env:GITHUB_STEP_SUMMARY
Write-Output "| Property | Value |" >> $env:GITHUB_STEP_SUMMARY
Write-Output "|----------|-------|" >> $env:GITHUB_STEP_SUMMARY
Write-Output "| **Module** | ``$ModuleName`` |" >> $env:GITHUB_STEP_SUMMARY
Write-Output "| **Version** | ``$NewVersion`` |" >> $env:GITHUB_STEP_SUMMARY
Write-Output "| **Target** | GitHub Packages |" >> $env:GITHUB_STEP_SUMMARY
Write-Output "" >> $env:GITHUB_STEP_SUMMARY

# ═══════════════════════════════════════════════════════════════════════════
# 🔧 Configuration
# ═══════════════════════════════════════════════════════════════════════════
$registryUri = "https://nuget.pkg.github.com/$RepositoryOwner/index.json"
$repoName = 'GitHubPackages'

# ═══════════════════════════════════════════════════════════════════════════
# 📦 Install K.PSGallery.PackageRepoProvider from GitHub Packages
# ═══════════════════════════════════════════════════════════════════════════
function Install-PackageRepoProvider {
    param([string]$Token, [string]$Owner)
    
    Write-Output "📦 Installing K.PSGallery.PackageRepoProvider from GitHub Packages..."
    
    # Create credential for GitHub Packages
    $secureToken = ConvertTo-SecureString $Token -AsPlainText -Force
    $credential = New-Object PSCredential($Owner, $secureToken)
    
    # Register GitHub Packages as PSResource repository (for installation)
    $tempRepoName = 'GHPackages-Temp'
    $uri = "https://nuget.pkg.github.com/$Owner/index.json"
    
    # Remove if exists
    Unregister-PSResourceRepository -Name $tempRepoName -ErrorAction SilentlyContinue
    
    # Register
    Register-PSResourceRepository -Name $tempRepoName -Uri $uri -Trusted -ErrorAction Stop
    
    # Install the provider module
    Install-PSResource -Name 'K.PSGallery.PackageRepoProvider' `
        -Repository $tempRepoName `
        -Credential $credential `
        -Scope CurrentUser `
        -TrustRepository `
        -ErrorAction Stop
    
    # Import the module
    Import-Module K.PSGallery.PackageRepoProvider -Force -ErrorAction Stop
    
    Write-Output "✅ K.PSGallery.PackageRepoProvider installed and imported"
    
    # Cleanup temp repository
    Unregister-PSResourceRepository -Name $tempRepoName -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════════
# 🚀 Main Publishing Logic
# ═══════════════════════════════════════════════════════════════════════════

# 🐛 DEBUG: Show initial state
Write-DebugInfo "Starting publish for $ModuleName v$NewVersion"
Show-ManifestDebugInfo -Path '.' -Context 'Initial Working Directory'

try {
    # Step 1: Install PackageRepoProvider from GitHub Packages
    Install-PackageRepoProvider -Token $GitHubToken -Owner $RepositoryOwner
    
    # 🐛 DEBUG: Check installed module
    Show-InstalledModuleDebugInfo -ModuleName 'K.PSGallery.PackageRepoProvider'
    
    Write-Output "📝 Registering repository: $repoName"
    
    # Step 2: Register the target repository using PackageRepoProvider
    Register-PackageRepo `
        -RepositoryName $repoName `
        -RegistryUri $registryUri `
        -Token $GitHubToken `
        -Trusted
    
    Write-Output "🚀 Publishing module: $ModuleName"
    
    # Step 3: Publish the module
    Publish-Package `
        -RepositoryName $repoName `
        -Token $GitHubToken
    
    # Success summary
    Write-Output "### ✅ Published via K.PSGallery.PackageRepoProvider" >> $env:GITHUB_STEP_SUMMARY
    Write-Output "" >> $env:GITHUB_STEP_SUMMARY
    Write-Output "- **Registry:** ``$registryUri``" >> $env:GITHUB_STEP_SUMMARY
    Write-Output "- **Package:** ``$ModuleName@$NewVersion``" >> $env:GITHUB_STEP_SUMMARY
    
    "package-published=true" >> $env:GITHUB_OUTPUT
    
    Write-Output "✅ Successfully published $ModuleName@$NewVersion to GitHub Packages"
}
catch {
    Write-Output "⚠️ PackageRepoProvider failed: $($_.Exception.Message)"
    Write-Output "🔄 Falling back to Publish-PSResource..."
    Write-Output "### ⚠️ Fallback: Publish-PSResource" >> $env:GITHUB_STEP_SUMMARY
    
    # ═══════════════════════════════════════════════════════════════════════
    # 🔄 Fallback: Built-in Publish-PSResource
    # ═══════════════════════════════════════════════════════════════════════
    try {
        # Create credential
        $secureToken = ConvertTo-SecureString $GitHubToken -AsPlainText -Force
        $credential = New-Object PSCredential($RepositoryOwner, $secureToken)
        
        # Register repository
        Unregister-PSResourceRepository -Name $repoName -ErrorAction SilentlyContinue
        Register-PSResourceRepository -Name $repoName -Uri $registryUri -Trusted -ErrorAction Stop
        
        # Find the EXACT module manifest file (not just any PSD1)
        # This is critical when multiple PSD1 files exist (e.g., PSScriptAnalyzerSettings.psd1)
        $manifestFile = Get-ChildItem -Path '.' -Filter "$ModuleName.psd1" -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        
        if (-not $manifestFile) {
            # Fallback: check subdirectory
            $moduleSubPath = Join-Path -Path '.' -ChildPath $ModuleName
            if (Test-Path $moduleSubPath) {
                $manifestFile = Get-ChildItem -Path $moduleSubPath -Filter "$ModuleName.psd1" -File -ErrorAction SilentlyContinue |
                    Select-Object -First 1
            }
        }
        
        if (-not $manifestFile) {
            throw "Module manifest '$ModuleName.psd1' not found in current directory or '$ModuleName' subdirectory"
        }
        
        # Use the directory containing the manifest
        $modulePath = $manifestFile.DirectoryName
        
        # 🐛 DEBUG: Show what path we're using for fallback
        Write-DebugInfo "Found manifest file: $($manifestFile.FullName)"
        Write-DebugInfo "Fallback modulePath resolved to: $modulePath"
        Show-ManifestDebugInfo -Path $modulePath -Context 'Fallback Publish Path'
        
        # Publish module
        Publish-PSResource `
            -Path $modulePath `
            -Repository $repoName `
            -ApiKey $GitHubToken `
            -ErrorAction Stop
        
        Write-Output "- ✅ Published via Publish-PSResource" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "- **Package:** ``$ModuleName@$NewVersion``" >> $env:GITHUB_STEP_SUMMARY
        
        "package-published=true" >> $env:GITHUB_OUTPUT
        
        Write-Output "✅ Successfully published $ModuleName@$NewVersion via fallback"
    }
    catch {
        Write-Error "❌ Package publishing failed: $($_.Exception.Message)"
        Write-Output "### ❌ Publishing Failed" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "" >> $env:GITHUB_STEP_SUMMARY
        Write-Output "``````" >> $env:GITHUB_STEP_SUMMARY
        Write-Output $_.Exception.Message >> $env:GITHUB_STEP_SUMMARY
        Write-Output "``````" >> $env:GITHUB_STEP_SUMMARY
        
        "package-published=false" >> $env:GITHUB_OUTPUT
        exit 1
    }
    finally {
        # Cleanup
        Unregister-PSResourceRepository -Name $repoName -ErrorAction SilentlyContinue
    }
}
finally {
    # Final cleanup - only if PackageRepoProvider was loaded
    if (Get-Command Remove-PackageRepo -ErrorAction SilentlyContinue) {
        Remove-PackageRepo -RepositoryName $repoName -ErrorAction SilentlyContinue
    }
}
