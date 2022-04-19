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
    Describe -Name 'GetNetworkRange' -Fixture {
        It 'Returns an array of IPAddress' {
            GetNetworkRange 1.2.3.4/32 -IncludeNetworkAndBroadcast | Should -BeOfType 'System.Net.IPAddress'
        }

        It 'Returns 255.255.255.255 when passed 255.255.255.255/32' {
            $Range = GetNetworkRange 0/30
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue

            $Range = GetNetworkRange 0.0.0.0/30
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue

            $Range = GetNetworkRange 0.0.0.0 255.255.255.252
            $Range -contains '0.0.0.1' | Should -BeTrue
            $Range -contains '0.0.0.2' | Should -BeTrue
        }

        It 'Accepts pipeline input' {
            '20/24' | GetNetworkRange | Select-Object -First 1 | Should -Be '20.0.0.1'
        }

        It 'Throws an error if passed something other than an IPAddress' {
            { GetNetworkRange 'abcd' } | Should -Throw
        }

        It 'Returns correct values when used with Start and End parameters' {
            $StartIP = [System.Net.IPAddress]'192.168.1.1'
            $EndIP = [System.Net.IPAddress]'192.168.2.10'
            $Assertion = GetNetworkRange -Start $StartIP -End $EndIP

            $Assertion.Count | Should -BeExactly 266
            $Assertion[0].IPAddressToString | Should -BeExactly '192.168.1.1'
            $Assertion[-1].IPAddressToString | Should -BeExactly '192.168.2.10'
        }
    }
}