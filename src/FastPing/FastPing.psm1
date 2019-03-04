# This psm1 is for local testing and development use only
# Sets the Script Path variable to the scripts invocation path.
$paths = @('Private', 'Public')

# dot source the parent import
if (Test-Path -Path "$PSScriptRoot\Constants.ps1")
{
    . $PSScriptRoot\Constants.ps1
}

if (Test-Path -Path "$PSScriptRoot\Classes.ps1")
{
    . $PSScriptRoot\Classes.ps1
}

foreach ($path in $paths)
{
    if (Test-Path -Path "$PSScriptRoot\$path")
    {
        $files = Get-ChildItem "$PSScriptRoot\$path" -Filter '*.ps1' -File

        foreach ($file in $files)
        {
            . $file.FullName
        }
    }
}