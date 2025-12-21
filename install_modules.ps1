<#
    .SYNOPSIS
    This script is used to install the required PowerShell Modules for the build process.
    It has a dependency on the PowerShell Gallery.
#>
$global:VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# Fix for PowerShell Gallery and TLS1.2
# https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name 'PowerShellGet' -MinimumVersion '2.2.4' -SkipPublisherCheck -Force -AllowClobber

# List of PowerShell Modules required for the build
$modulesToInstall = @(
    @{
        ModuleName    = 'InvokeBuild'
        ModuleVersion = '5.9.10'
    }
    @{
        ModuleName    = 'Pester'
        ModuleVersion = '4.10.1'
    }
    @{
        ModuleName    = 'platyPS'
        ModuleVersion = '0.14.2'
    }
    @{
        ModuleName    = 'PSScriptAnalyzer'
        ModuleVersion = '1.18.3'
    }
)

$installModule = @{
    Scope              = 'CurrentUser'
    AllowClobber       = $true
    Force              = $true
    SkipPublisherCheck = $true
    Verbose            = $false
}

$installedModules = Get-Module -ListAvailable

foreach ($module in $modulesToInstall) {
    Write-Host ('  - {0} {1}' -f $module.ModuleName, $module.ModuleVersion)

    if ($installedModules.Where( { $_.Name -eq $module.ModuleName -and $_.Version -eq $module.ModuleVersion } )) {
        Write-Host ('      Already installed. Skipping...' -f $module.ModuleName)
        continue
    }

    Install-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion @installModule
    Import-Module -Name $module.ModuleName -Force
}

Get-Module -ListAvailable | Select-Object -Property Name, Version | Sort-Object -Property Name | Format-Table
