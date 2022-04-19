<#
    .NOTES
    This code is copied from the Indented.Net.IP module (https://github.com/indented-automation/Indented.Net.IP).
    The copy is due to not wanting to take a dependency, and that module licensed with a permissive license.
    Thanks Chris Dent!
#>
Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

InModuleScope -ModuleName $ModuleName -ScriptBlock {
    Describe 'ConvertToDecimalIP' {
        It 'Returns a unsigned 32-bit integer' {
            ConvertToDecimalIP 0.0.0.0 | Should -BeOfType UInt32
        }

        It 'Converts 0.0.0.0 to 0' {
            ConvertToDecimalIP 0.0.0.0 | Should -Be 0
        }

        It 'Converts 255.255.255.255 to 4294967295' {
            ConvertToDecimalIP 255.255.255.255 | Should -Be 4294967295
        }

        It 'Accepts pipeline input' {
            '0.0.0.0' | ConvertToDecimalIP | Should -Be 0
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { ConvertToDecimalIP 'abcd' } | Should -Throw
        }
    }
}