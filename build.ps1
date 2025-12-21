<#
.SYNOPSIS
    Build script for PowerShell modules with auto-detection.

.DESCRIPTION
    Parameter-driven build script that assembles PowerShell modules, runs tests,
    performs code analysis, and creates distribution packages.
    
    Auto-detects module name from manifest files in src/ directory, eliminating
    the need for manual configuration or find/replace operations.
    
    When running in GitHub Actions (auto-detected) or with -CI parameter, the script
    compares a content hash of build-relevant files to skip unnecessary builds.

.PARAMETER Build
    Assemble PowerShell module from source files.

.PARAMETER Test
    Run PowerShell Pester tests with code coverage.

.PARAMETER Analyze
    Run code analysis with PSScriptAnalyzer.

.PARAMETER Fix
    Auto-fix code formatting issues with Invoke-Formatter.

.PARAMETER Clean
    Remove build artifacts (Artifacts/, Archive/, DeploymentArtifacts/).

.PARAMETER Package
    Create distribution ZIP from assembled PowerShell module.

.PARAMETER Docs
    Generate PowerShell function documentation using PlatyPS.

.PARAMETER Artifact
    Test the assembled artifact module instead of the source module.

.PARAMETER Full
    Execute complete build workflow: Clean, Analyze, Test, Build, Package.

.PARAMETER CI
    Enable CI mode with content hash comparison. Automatically enabled when
    running in GitHub Actions (detected via GITHUB_ACTIONS environment variable).
    Compares hash of build-relevant files to skip builds when content unchanged.

.PARAMETER HashFile
    Path to the hash file for CI mode comparison. In GitHub Actions, this file
    is downloaded from artifacts before the build and uploaded after success.
    Default: .build\content-hash.txt

.EXAMPLE
    .\build.ps1 -Build
    
    Assemble PowerShell module to Artifacts directory.

.EXAMPLE
    .\build.ps1 -Test
    
    Run PowerShell Pester tests with code coverage validation.

.EXAMPLE
    .\build.ps1 -Docs
    
    Generate function documentation using PlatyPS.

.EXAMPLE
    .\build.ps1 -Full
    
    Execute complete build workflow.

.EXAMPLE
    .\build.ps1 -Full -CI
    
    Execute build workflow with content hash comparison (skips if unchanged).

.EXAMPLE
    .\build.ps1 -Full -CI -HashFile .build/my-hash.txt
    
    Execute build workflow using custom hash file location.

.NOTES
    Exit Codes:
    0 - Success (or skipped in CI mode due to no changes)
    1 - General error or validation failure
    
    Requirements:
    - PowerShell 5.1 or higher
    - Pester 5.3.0+ (for tests)
    - PSScriptAnalyzer (for analysis)
    
    CI Mode:
    - Auto-detected in GitHub Actions via GITHUB_ACTIONS=true
    - Calculates SHA256 hash of all build-relevant files
    - Compares against previous hash to detect changes
    - Skips build if content hash matches (no changes)
    - Saves new hash after successful build
#>

[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$Test,
    [switch]$Analyze,
    [switch]$Fix,
    [switch]$Clean,
    [switch]$Package,
    [switch]$Docs,
    [switch]$Artifact,
    [switch]$Full,
    [switch]$CI,
    [string]$HashFile
)

#region Helper Functions

function Initialize-BuildEnvironment {
    <#
    .SYNOPSIS
        Initializes the build environment with auto-detected module name.
    #>
    
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw 'PowerShell 5.0 or higher is required. Current version: {0}' -f $PSVersionTable.PSVersion
    }
    
    $repositoryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '.'))
    $srcPath = [System.IO.Path]::Combine($repositoryRoot, 'src')
    
    $manifestFiles = [System.IO.Directory]::GetFiles($srcPath, '*.psd1', [System.IO.SearchOption]::AllDirectories)
    
    if ($manifestFiles.Count -eq 0) {
        throw 'No module manifest (.psd1) files found in src/ directory'
    }
    
    $manifestPath = $manifestFiles[0]
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($manifestPath)
    
    if (-not [System.IO.File]::Exists($manifestPath)) {
        throw 'Module manifest not found at: {0}' -f $manifestPath
    }
    
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    
    return [PSCustomObject]@{
        RepositoryRoot = $repositoryRoot
        ModuleName = $moduleName
        ModuleVersion = $manifest.ModuleVersion
        ModuleDescription = $manifest.Description
        FunctionsToExport = $manifest.FunctionsToExport
        SourcePath = [System.IO.Path]::Combine($repositoryRoot, 'src', $moduleName)
        TestsPath = [System.IO.Path]::Combine($repositoryRoot, 'src', 'Tests')
        ArtifactsPath = [System.IO.Path]::Combine($repositoryRoot, 'Artifacts')
        ArchivePath = [System.IO.Path]::Combine($repositoryRoot, 'Archive')
        DeploymentArtifactsPath = [System.IO.Path]::Combine($repositoryRoot, 'DeploymentArtifacts')
        DocsPath = [System.IO.Path]::Combine($repositoryRoot, 'docs')
        FunctionsDocsPath = [System.IO.Path]::Combine($repositoryRoot, 'docs', 'functions')
        PesterOutputFormat = 'CoverageGutters'
        CodeCoverageThreshold = 80
    }
}

function Get-PlatformInfo {
    <#
    .SYNOPSIS
        Detects platform and architecture.
    #>
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) {
            $platform = 'Windows'
        }
        elseif ($IsMacOS) {
            $platform = 'macOS'
        }
        else {
            $platform = 'Linux'
        }
    }
    else {
        $platform = 'Windows'
    }
    
    $runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    
    $architecture = switch ($runtimeArch) {
        'X64' { 'x64' }
        'Arm64' { 'arm64' }
        'X86' { 'x86' }
        'Arm' { 'arm' }
        default { 'unknown' }
    }
    
    return [PSCustomObject]@{
        Platform = $platform
        Architecture = $architecture
    }
}

#endregion

#region CI Change Detection

function Test-GitHubActionsEnvironment {
    <#
    .SYNOPSIS
        Detects if running in GitHub Actions environment.
    #>
    
    $githubActions = [System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS')
    return $githubActions -eq 'true'
}

function Get-BuildContentHash {
    <#
    .SYNOPSIS
        Calculates a SHA256 hash of all build-relevant files.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,
        
        [Parameter(Mandatory)]
        [string]$ModuleName
    )
    
    $searchLocations = @(
        @{ Path = @('src', $ModuleName); Pattern = '*.ps1' },
        @{ Path = @('src', $ModuleName); Pattern = '*.psd1' },
        @{ Path = @('src', $ModuleName); Pattern = '*.psm1' },
        @{ Path = @('src', $ModuleName, 'Public'); Pattern = '*.ps1' },
        @{ Path = @('src', $ModuleName, 'Private'); Pattern = '*.ps1' },
        @{ Path = @('src', 'Tests', 'Unit'); Pattern = '*.ps1' },
        @{ Path = @('src', 'Tests', 'Build'); Pattern = '*.ps1' },
        @{ Path = @('.build'); Pattern = '*.ps1' }
    )
    
    $rootFiles = @(
        'build.ps1',
        'install_modules.ps1',
        'install_nuget.ps1'
    )
    
    $allContent = [System.Text.StringBuilder]::new()
    
    foreach ($file in $rootFiles) {
        $filePath = [System.IO.Path]::Combine($RepositoryRoot, $file)
        if ([System.IO.File]::Exists($filePath)) {
            $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
            [void]$allContent.AppendLine("### $file ###")
            [void]$allContent.AppendLine($content)
        }
    }
    
    foreach ($location in $searchLocations) {
        $pathSegments = @($RepositoryRoot) + $location.Path
        $searchPath = [System.IO.Path]::Combine($pathSegments)
        $searchPattern = $location.Pattern
        
        if ([System.IO.Directory]::Exists($searchPath)) {
            $files = [System.IO.Directory]::GetFiles($searchPath, $searchPattern) | Sort-Object
            foreach ($file in $files) {
                $relativePath = $file.Substring($RepositoryRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
                $normalizedPath = $relativePath -replace '\\', '/'
                $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
                [void]$allContent.AppendLine("### $normalizedPath ###")
                [void]$allContent.AppendLine($content)
            }
        }
    }
    
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($allContent.ToString())
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    
    return $hash.ToLower()
}

function Get-PreviousBuildHash {
    <#
    .SYNOPSIS
        Reads the previous build hash from the hash file.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$HashFilePath
    )
    
    if ([System.IO.File]::Exists($HashFilePath)) {
        $content = [System.IO.File]::ReadAllText($HashFilePath, [System.Text.Encoding]::UTF8).Trim()
        return $content
    }
    
    return $null
}

function Save-BuildHash {
    <#
    .SYNOPSIS
        Saves the current build hash to the hash file.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$HashFilePath,
        
        [Parameter(Mandatory)]
        [string]$Hash
    )
    
    $directory = [System.IO.Path]::GetDirectoryName($HashFilePath)
    if (-not [System.IO.Directory]::Exists($directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }
    
    [System.IO.File]::WriteAllText($HashFilePath, $Hash, [System.Text.Encoding]::UTF8)
}

#endregion

#region PowerShell Operations

function Invoke-PowerShellBuild {
    <#
    .SYNOPSIS
        Assembles the PowerShell module for distribution.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Building PowerShell module...' -ForegroundColor Cyan
    
    $sourcePath = $Config.SourcePath
    $artifactsPath = $Config.ArtifactsPath
    $moduleName = $Config.ModuleName
    
    $manifestSource = [System.IO.Path]::Combine($sourcePath, ('{0}.psd1' -f $moduleName))
    $manifestDest = [System.IO.Path]::Combine($artifactsPath, ('{0}.psd1' -f $moduleName))
    
    if (-not [System.IO.File]::Exists($manifestSource)) {
        Write-Host ('Module manifest not found at: {0}' -f $manifestSource) -ForegroundColor Red
        return @{ Success = $false }
    }
    
    if (-not [System.IO.Directory]::Exists($artifactsPath)) {
        Write-Host '  Creating Artifacts directory...' -ForegroundColor Gray
        [System.IO.Directory]::CreateDirectory($artifactsPath) | Out-Null
    }
    
    Write-Host '  Copying module manifest...' -ForegroundColor Gray
    [System.IO.File]::Copy($manifestSource, $manifestDest, $true)
    
    # Copy format files if they exist
    $formatFiles = [System.IO.Directory]::GetFiles($sourcePath, '*.ps1xml', [System.IO.SearchOption]::TopDirectoryOnly)
    foreach ($formatFile in $formatFiles) {
        $formatFileName = [System.IO.Path]::GetFileName($formatFile)
        $formatDest = [System.IO.Path]::Combine($artifactsPath, $formatFileName)
        Write-Host "  Copying format file: $formatFileName" -ForegroundColor Gray
        [System.IO.File]::Copy($formatFile, $formatDest, $true)
    }
    
    Write-Host '  Combining PowerShell scripts...' -ForegroundColor Gray
    $sb = [System.Text.StringBuilder]::new()
    
    $classesFile = [System.IO.Path]::Combine($sourcePath, 'Classes.ps1')
    if ([System.IO.File]::Exists($classesFile)) {
        $content = [System.IO.File]::ReadAllText($classesFile, [System.Text.Encoding]::UTF8)
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine()
    }
    
    $ps1Files = [System.IO.Directory]::GetFiles($sourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    foreach ($file in $ps1Files) {
        $fileName = [System.IO.Path]::GetFileName($file)
        if ($fileName -eq 'Classes.ps1') {
            continue
        }
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine()
    }
    
    $psmPath = [System.IO.Path]::Combine($artifactsPath, ('{0}.psm1' -f $moduleName))
    [System.IO.File]::WriteAllText($psmPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
    
    Write-Host 'PowerShell module build completed successfully.' -ForegroundColor Green
    return @{ Success = $true }
}

function Invoke-PowerShellTest {
    <#
    .SYNOPSIS
        Runs PowerShell Pester tests with code coverage validation.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,
        
        [switch]$Artifact
    )
    
    if ($Artifact) {
        Write-Host 'Running PowerShell tests against artifact module...' -ForegroundColor Cyan
        $modulePath = $Config.ArtifactsPath
        $manifestPath = [System.IO.Path]::Combine($modulePath, ('{0}.psd1' -f $Config.ModuleName))
        
        if (-not [System.IO.File]::Exists($manifestPath)) {
            Write-Host ('Artifact module not found at: {0}' -f $manifestPath) -ForegroundColor Red
            Write-Host ''
            Write-Host 'Please build the PowerShell module first:' -ForegroundColor Yellow
            Write-Host '  .\build.ps1 -Build' -ForegroundColor Cyan
            Write-Host ''
            exit 4
        }
    }
    else {
        Write-Host 'Running PowerShell tests against source module...' -ForegroundColor Cyan
        $modulePath = $Config.SourcePath
        $manifestPath = [System.IO.Path]::Combine($modulePath, ('{0}.psd1' -f $Config.ModuleName))
    }
    
    $platformInfo = Get-PlatformInfo
    
    if ($Artifact) {
        $coverageFiles = @()
        $enableCoverage = $false
    }
    else {
        $coverageFiles = [System.IO.Directory]::GetFiles($Config.SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories) | 
            Where-Object { -not [System.IO.Path]::GetFileName($_).StartsWith('_') }
        $enableCoverage = $true
    }
    
    $testPath = $Config.TestsPath
    
    if ($Artifact) {
        $platformName = switch ($platformInfo.Platform) {
            'Windows' { 'windows' }
            'macOS' { 'macos' }
            'Linux' { 'linux' }
            default { 'unknown' }
        }
        $archName = $platformInfo.Architecture
        
        if ($platformInfo.Platform -eq 'Windows') {
            $pwshEdition = if ($PSVersionTable.PSVersion.Major -ge 6) { 'core' } else { 'desktop' }
            $testReportName = 'test-results-{0}-{1}-{2}.xml' -f $platformName, $archName, $pwshEdition
        }
        else {
            $testReportName = 'test-results-{0}-{1}.xml' -f $platformName, $archName
        }
        $testReportPath = [System.IO.Path]::Combine($Config.RepositoryRoot, $testReportName)
    }
    else {
        $testReportPath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'test_report.xml')
    }
    $coveragePath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'coverage.xml')
    $absoluteManifestPath = [System.IO.Path]::GetFullPath($manifestPath)
    $moduleSource = if ($Artifact) { 'artifact' } else { 'source' }
    
    $pesterScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-PesterTests.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $pesterScriptPath,
        '-ModuleName', $Config.ModuleName,
        '-ManifestPath', $absoluteManifestPath,
        '-TestPath', $testPath,
        '-TestReportPath', $testReportPath,
        '-ModuleSource', $moduleSource
    )
    
    $coverageFilesPath = $null
    if ($enableCoverage) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $coverageFilesPath = [System.IO.Path]::Combine($tempDir, ('pester_coverage_files_{0}.txt' -f [System.Guid]::NewGuid().ToString('N')))
        $coverageFiles | Out-File -FilePath $coverageFilesPath -Encoding UTF8
        
        $scriptArgs += '-EnableCoverage'
        $scriptArgs += '-CoveragePath', $coveragePath
        $scriptArgs += '-CoverageThreshold', $Config.CodeCoverageThreshold
        $scriptArgs += '-CoverageFormat', $Config.PesterOutputFormat
        $scriptArgs += '-CoverageFilesPath', $coverageFilesPath
    }
    try {
        $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
        $failedCount = $process.ExitCode
    }
    finally {
        if ($enableCoverage -and $coverageFilesPath -and [System.IO.File]::Exists($coverageFilesPath)) {
            try {
                [System.IO.File]::Delete($coverageFilesPath)
            }
            catch {
                Write-Warning ('Failed to delete temporary coverage file: {0}' -f $coverageFilesPath)
            }
        }
    }
    
    $totalTests = 0
    $failedTests = 0
    $coveragePercent = 0
    
    if ([System.IO.File]::Exists($testReportPath)) {
        [xml]$testXml = Get-Content -Path $testReportPath
        $totalTests = [int]$testXml.testsuites.tests
        $failedTests = [int]$testXml.testsuites.failures
        
        Write-Host ('  Tests: {0} total, {1} failed' -f $totalTests, $failedTests) -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Red' })
        
        if ($enableCoverage -and [System.IO.File]::Exists($coveragePath)) {
            [xml]$coverageXml = Get-Content -Path $coveragePath
            
            $lineCounter = $coverageXml.report.counter | Where-Object { $_.type -eq 'LINE' }
            if ($lineCounter) {
                $commandsAnalyzed = [int]$lineCounter.missed + [int]$lineCounter.covered
                $commandsExecuted = [int]$lineCounter.covered
                
                if ($commandsAnalyzed -gt 0) {
                    $coveragePercent = [math]::Round(($commandsExecuted / $commandsAnalyzed * 100), 2)
                    $coverageColor = if ($coveragePercent -ge $Config.CodeCoverageThreshold) { 'Green' } else { 'Red' }
                    Write-Host ('  Code Coverage: {0}% ({1}/{2} commands)' -f $coveragePercent, $commandsExecuted, $commandsAnalyzed) -ForegroundColor $coverageColor
                    
                    if ($coveragePercent -lt $Config.CodeCoverageThreshold) {
                        Write-Host ('Failed to meet code coverage threshold of {0}% with only {1}% coverage' -f $Config.CodeCoverageThreshold, $coveragePercent) -ForegroundColor Red
                        return @{
                            Success = $false
                            ExitCode = 1
                            TotalTests = $totalTests
                            FailedTests = $failedTests
                            CoveragePercent = $coveragePercent
                        }
                    }
                }
            }
        }
        elseif ($Artifact) {
            Write-Host '  Code Coverage: Skipped (artifact testing)' -ForegroundColor Gray
        }
    }
    
    if ($failedCount -eq 0) {
        Write-Host 'PowerShell tests passed.' -ForegroundColor Green
    } else {
        Write-Host ('PowerShell tests failed with {0} failure(s).' -f $failedCount) -ForegroundColor Red
    }
    
    return @{
        Success = ($failedCount -eq 0)
        ExitCode = $failedCount
        TotalTests = $totalTests
        FailedTests = $failedTests
        CoveragePercent = $coveragePercent
    }
}

function Invoke-PowerShellAnalyze {
    <#
    .SYNOPSIS
        Runs PSScriptAnalyzer on PowerShell module and test files.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Running PowerShell code analysis...' -ForegroundColor Cyan
    
    $analyzerScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-ScriptAnalysis.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $analyzerScriptPath,
        '-SourcePath', $Config.SourcePath,
        '-TestsPath', $Config.TestsPath
    )
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
    
    if ($exitCode -eq 0) {
        return @{
            Success = $true
            IssueCount = 0
        }
    } else {
        return @{
            Success = $false
            IssueCount = -1
        }
    }
}

function Invoke-PowerShellFix {
    <#
    .SYNOPSIS
        Auto-formats PowerShell module files using Invoke-Formatter with OTBS style.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Running PowerShell code formatter...' -ForegroundColor Cyan
    
    $files = [System.IO.Directory]::GetFiles($Config.SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    
    if ($files.Count -eq 0) {
        Write-Host 'No PowerShell files found to format.' -ForegroundColor Yellow
        return @{
            Success = $true
            ModifiedFiles = @()
        }
    }
    
    $formatterScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-CodeFormatter.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $formatterScriptPath,
        '-RepositoryRoot', $Config.RepositoryRoot,
        '-SourcePath', $Config.SourcePath
    )
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
    
    return @{
        Success = ($exitCode -eq 0)
        ModifiedFiles = @()
    }
}

function Invoke-PowerShellClean {
    <#
    .SYNOPSIS
        Removes PowerShell build artifacts and recreates empty directories.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Cleaning PowerShell build artifacts...' -ForegroundColor Cyan
    
    $directories = @(
        $Config.ArchivePath
        $Config.ArtifactsPath
        $Config.DeploymentArtifactsPath
    )
    
    foreach ($dir in $directories) {
        if ([System.IO.Directory]::Exists($dir)) {
            Remove-Item -Path $dir -Force -Recurse -ErrorAction SilentlyContinue
            $relativePath = $dir.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
            Write-Host ('  Removed: {0}' -f $relativePath) -ForegroundColor Gray
        }
    }
    
    foreach ($dir in $directories) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        $relativePath = $dir.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
        Write-Host ('  Created: {0}' -f $relativePath) -ForegroundColor Gray
    }
    
    Write-Host 'PowerShell artifacts cleaned successfully.' -ForegroundColor Green
    return @{ Success = $true }
}

function Invoke-PowerShellPackage {
    <#
    .SYNOPSIS
        Creates distribution ZIP package from assembled PowerShell module.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Creating PowerShell module package...' -ForegroundColor Cyan
    
    if (-not [System.IO.Directory]::Exists($Config.ArtifactsPath)) {
        Write-Host 'Artifacts directory not found. Run -Build first.' -ForegroundColor Red
        return @{ Success = $false }
    }
    
    if (-not [System.IO.Directory]::Exists($Config.DeploymentArtifactsPath)) {
        Write-Host '  Creating DeploymentArtifacts directory...' -ForegroundColor Gray
        [System.IO.Directory]::CreateDirectory($Config.DeploymentArtifactsPath) | Out-Null
    }
    
    $zipFileName = '{0}_{1}.zip' -f $Config.ModuleName, $Config.ModuleVersion
    $zipFilePath = [System.IO.Path]::Combine($Config.DeploymentArtifactsPath, $zipFileName)
    
    if ([System.IO.File]::Exists($zipFilePath)) {
        [System.IO.File]::Delete($zipFilePath)
    }
    
    Write-Host ('  Creating ZIP: {0}' -f $zipFileName) -ForegroundColor Gray
    
    if ($PSEdition -eq 'Desktop') {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }
    
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Config.ArtifactsPath, $zipFilePath)
    
    $fileInfo = [System.IO.FileInfo]::new($zipFilePath)
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host ('  Package created: {0} ({1} MB)' -f $zipFileName, $fileSizeMB) -ForegroundColor Green
    Write-Host ('  Location: {0}' -f $zipFilePath) -ForegroundColor Gray
    
    return @{
        Success = $true
        ZipFilePath = $zipFilePath
        ZipFileName = $zipFileName
    }
}

function Invoke-PowerShellDocs {
    <#
    .SYNOPSIS
        Generates PowerShell function documentation using PlatyPS.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $scriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-DocumentationGeneration.ps1')
    
    if (-not [System.IO.File]::Exists($scriptPath)) {
        Write-Host 'Documentation generation script not found.' -ForegroundColor Red
        return @{ Success = $false }
    }
    
    try {
        & $scriptPath -ModuleName $Config.ModuleName -ModulePath $Config.ArtifactsPath -OutputPath $Config.FunctionsDocsPath -ErrorAction Stop
        return @{ Success = $true }
    }
    catch {
        Write-Host ('Documentation generation failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
        return @{ Success = $false }
    }
}

#endregion

#region Parameter Validation and CI Detection

$isGitHubActions = Test-GitHubActionsEnvironment
if ($isGitHubActions -and -not $CI) {
    Write-Host 'GitHub Actions environment detected - enabling CI mode' -ForegroundColor Cyan
    $CI = $true
}

if ($Full) {
    $Clean = $true
    $Analyze = $true
    $Test = $true
    $Build = $true
    $Package = $true
}

$hasAction = $Build -or $Test -or $Analyze -or $Fix -or $Clean -or $Package -or $Docs
$hasWorkflow = $Full

if (-not $hasAction -and -not $hasWorkflow) {
    Write-Host 'PowerShell Module Build Script'
    Write-Host ''
    Write-Host 'Usage: .\build.ps1 [-Build] [-Test] [-Analyze] [-Fix] [-Clean] [-Package] [-Docs] [-Full]'
    Write-Host ''
    Write-Host 'CI Options:'
    Write-Host '  -CI                 Enable content hash comparison (auto-enabled in GitHub Actions)'
    Write-Host '  -HashFile <path>    Path to hash file for comparison (default: .build\content-hash.txt)'
    Write-Host ''
    Write-Host 'For detailed help, run: Get-Help .\build.ps1'
    Write-Host 'For examples, run: Get-Help .\build.ps1 -Examples'
    exit 0
}

#endregion

#region Main Execution

try {
    $config = Initialize-BuildEnvironment
    
    if ([string]::IsNullOrEmpty($HashFile)) {
        $HashFile = [System.IO.Path]::Combine('.build', 'content-hash.txt')
    }
    
    $hashFilePath = if ([System.IO.Path]::IsPathRooted($HashFile)) {
        $HashFile
    }
    else {
        [System.IO.Path]::Combine($config.RepositoryRoot, $HashFile)
    }
    
    $skipBuild = $false
    $currentHash = $null
    
    if ($CI) {
        Write-Host ''
        Write-Host 'CI Mode: Calculating content hash...' -ForegroundColor Cyan
        
        $currentHash = Get-BuildContentHash -RepositoryRoot $config.RepositoryRoot -ModuleName $config.ModuleName
        Write-Host ('  Current hash: {0}' -f $currentHash.Substring(0, 16)) -ForegroundColor Gray
        
        $previousHash = Get-PreviousBuildHash -HashFilePath $hashFilePath
        
        if ($previousHash) {
            Write-Host ('  Previous hash: {0}' -f $previousHash.Substring(0, 16)) -ForegroundColor Gray
            
            if ($currentHash -eq $previousHash) {
                Write-Host ''
                Write-Host 'CI Mode: Content hash unchanged - skipping build' -ForegroundColor Green
                Write-Host ('  Hash file: {0}' -f $hashFilePath) -ForegroundColor Gray
                $skipBuild = $true
            }
            else {
                Write-Host ''
                Write-Host 'CI Mode: Content hash changed - running build' -ForegroundColor Yellow
            }
        }
        else {
            Write-Host '  Previous hash: (none found)' -ForegroundColor Gray
            Write-Host ''
            Write-Host 'CI Mode: No previous hash - running full build' -ForegroundColor Yellow
        }
        
        Write-Host ''
    }
    
    if ($skipBuild) {
        exit 0
    }
    
    if ($Clean) {
        $result = Invoke-PowerShellClean -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Fix) {
        $result = Invoke-PowerShellFix -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Analyze) {
        $result = Invoke-PowerShellAnalyze -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Build) {
        $result = Invoke-PowerShellBuild -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Test) {
        $result = Invoke-PowerShellTest -Config $config -Artifact:$Artifact
        if (-not $result.Success) {
            exit $result.ExitCode
        }
    }
    
    if ($Package) {
        $result = Invoke-PowerShellPackage -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Docs) {
        $result = Invoke-PowerShellDocs -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($CI -and $currentHash) {
        Write-Host ''
        Write-Host 'CI Mode: Saving content hash...' -ForegroundColor Cyan
        Save-BuildHash -HashFilePath $hashFilePath -Hash $currentHash
        Write-Host ('  Hash saved to: {0}' -f $hashFilePath) -ForegroundColor Gray
    }
    
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

#endregion
