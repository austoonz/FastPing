param(
    [Parameter(Mandatory)]
    [string]$ModuleName,
    
    [Parameter(Mandatory)]
    [string]$ManifestPath,
    
    [Parameter(Mandatory)]
    $TestPath,
    
    [Parameter(Mandatory)]
    [string]$TestReportPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableCoverage,
    
    [Parameter(Mandatory = $false)]
    [string]$CoveragePath,
    
    [Parameter(Mandatory = $false)]
    [int]$CoverageThreshold,
    
    [Parameter(Mandatory = $false)]
    [string]$CoverageFormat,
    
    [Parameter(Mandatory = $false)]
    [string]$CoverageFilesPath,
    
    [Parameter(Mandatory)]
    [string]$ModuleSource
)

Import-Module Pester

Get-Module -Name $ModuleName | Remove-Module -Force -ErrorAction SilentlyContinue

Import-Module $ManifestPath -Force -Global

$module = Get-Module -Name $ModuleName
if (-not $module) {
    Write-Error 'Module failed to load'
    exit 1
}
Write-Host "Module root:     $($module.ModuleBase)" -ForegroundColor Cyan
Write-Host "Module manifest: $ManifestPath" -ForegroundColor Cyan

$config = New-PesterConfiguration

# Handle both single path (string) and multiple paths (array)
if ($TestPath -is [array]) {
    $config.Run.Path = $TestPath
} else {
    $config.Run.Path = $TestPath
}
$config.Run.PassThru = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = $TestReportPath
$config.TestResult.OutputFormat = 'JUnitXml'
$config.Output.Verbosity = 'Normal'
$config.Output.CIFormat = 'GithubActions'
$config.CodeCoverage.Enabled = $EnableCoverage.IsPresent

if ($EnableCoverage.IsPresent) {
    $config.CodeCoverage.CoveragePercentTarget = $CoverageThreshold
    $config.CodeCoverage.OutputPath = $CoveragePath
    $config.CodeCoverage.OutputFormat = $CoverageFormat
    
    if ($CoverageFilesPath -and [System.IO.File]::Exists($CoverageFilesPath)) {
        $coverageFiles = Get-Content -Path $CoverageFilesPath | Where-Object { $_.Trim() -ne '' }
        $config.CodeCoverage.Path = $coverageFiles
    }
}

$result = Invoke-Pester -Configuration $config
exit $result.FailedCount
