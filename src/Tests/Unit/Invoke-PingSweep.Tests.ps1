$ModuleName = 'FastPing'

InModuleScope -ModuleName $ModuleName -ScriptBlock {
    Describe -Name 'Invoke-PingSweep' -Fixture {
        Context -Name 'Ping Sweep Tests' -Fixture {
            Mock -CommandName 'Invoke-FastPing' -MockWith {
                $HostName | ForEach-Object {
                    if ($_ -eq '1.1.1.15') {
                        [PSCustomObject]@{
                            Online = $false
                        }
                    } else {
                        [PSCustomObject]@{
                            Online = $true
                        }
                    }
                }
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

            $testCases = @(
                @{
                    ExpectedCount = 10
                    StartIP       = '1.1.1.1'
                    EndIP         = '1.1.1.10'
                }
            )
            It -Name 'Supports ping sweeps with online only responses' -TestCases $testCases -Test {
                param ($ExpectedCount, $StartIP, $EndIP)

                $assertion = Invoke-PingSweep -StartIP $StartIP -EndIP $EndIP -ReturnOnlineOnly
                $assertion.Count | Should -BeExactly $ExpectedCount
            }
        }
    }
}