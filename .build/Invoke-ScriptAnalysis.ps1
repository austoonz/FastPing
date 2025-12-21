param(
    [Parameter(Mandatory)]
    [string]$SourcePath,
    
    [string]$TestsPath
)

Import-Module PSScriptAnalyzer -ErrorAction Stop

$allIssues = @()

Write-Host '  Analyzing module files...' -ForegroundColor Gray
$moduleParams = @{
    Path = $SourcePath
    ExcludeRule = @('PSAvoidGlobalVars')
    Severity = @('Error', 'Warning')
    Recurse = $true
}

$moduleResults = Invoke-ScriptAnalyzer @moduleParams
if ($moduleResults) {
    $allIssues += $moduleResults
}

if ($allIssues.Count -gt 0) {
    Write-Host ''
    $allIssues | Format-Table -AutoSize
    Write-Host "Found $($allIssues.Count) PSScriptAnalyzer issue(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'PowerShell code analysis passed.' -ForegroundColor Green
exit 0
