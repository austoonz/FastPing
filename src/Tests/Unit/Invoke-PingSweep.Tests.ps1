Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

InModuleScope -ModuleName $ModuleName -ScriptBlock {
    Describe -Name 'Invoke-PingSweep' -Fixture {
        Context -Name 'Ping Sweet Tests' -Fixture {
            Mock -CommandName 'Invoke-FastPing' -MockWith {
                $HostName | ForEach-Object { $true }
            }

            $testCases = @(
                @{
                    ExpectedCount = 2
                    StartIP       = '1.1.1.1'
                    EndIP         = '1.1.1.2'
                }
                @{
                    ExpectedCount = 10
                    StartIP       = '1.1.1.1'
                    EndIP         = '1.1.1.10'
                }
            )
            It -Name 'Supports ping sweeps: Count <ExpectedCount>' -TestCases $testCases -Test {
                param ($ExpectedCount, $StartIP, $EndIP)

                $assertion = Invoke-PingSweep -StartIP $StartIP -EndIP $EndIP
                $assertion.Count | Should -BeExactly $ExpectedCount
            }

            $testCases = @(
                @{
                    ExpectedCount = 254
                    IPAddress     = '192.168.1.0'
                    SubnetMask    = '255.255.255.0'
                }
                @{
                    ExpectedCount = 14
                    IPAddress     = '192.168.1.0'
                    SubnetMask    = '255.255.255.240'
                }

                @{
                    ExpectedCount = 2
                    IPAddress     = '192.168.1.0'
                    SubnetMask    = '255.255.255.252'
                }
            )
            It -Name 'Supports ping sweeps from IPAddress and SubnetMask: Count <ExpectedCount>' -TestCases $testCases -Test {
                param ($ExpectedCount, $IPAddress, $SubnetMask)

                $assertion = Invoke-PingSweep -IPAddress $IPAddress -SubnetMask $SubnetMask
                $assertion.Count | Should -BeExactly $ExpectedCount
            }
        }
    }
}