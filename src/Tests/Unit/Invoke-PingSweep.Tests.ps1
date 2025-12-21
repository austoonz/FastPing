$ModuleName = 'FastPing'

InModuleScope -ModuleName $ModuleName -ScriptBlock {
    Describe -Name 'Invoke-PingSweep' -Fixture {
        BeforeAll {
            Mock -CommandName 'Invoke-FastPing' -MockWith {
                $HostName | ForEach-Object {
                    if ($_ -eq '203.0.113.15') {
                        [PSCustomObject]@{
                            HostName = $_
                            Online = $false
                            HostNameAsVersion = $_
                        }
                    } else {
                        [PSCustomObject]@{
                            HostName = $_
                            Online = $true
                            HostNameAsVersion = $_
                        }
                    }
                }
            }
        }
        
        Context -Name 'Ping Sweep Tests' -Fixture {

            $testCases = @(
                @{
                    ExpectedCount = 2
                    StartIP       = '203.0.113.1'
                    EndIP         = '203.0.113.2'
                }
                @{
                    ExpectedCount = 10
                    StartIP       = '203.0.113.1'
                    EndIP         = '203.0.113.10'
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
                    IPAddress     = '198.51.100.0'
                    SubnetMask    = '255.255.255.0'
                }
                @{
                    ExpectedCount = 14
                    IPAddress     = '198.51.100.0'
                    SubnetMask    = '255.255.255.240'
                }

                @{
                    ExpectedCount = 2
                    IPAddress     = '198.51.100.0'
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
                    StartIP       = '203.0.113.1'
                    EndIP         = '203.0.113.10'
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