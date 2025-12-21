$global:WarningPreference = 'SilentlyContinue'

$ModuleName = 'FastPing'

Describe -Name 'Invoke-FastPing' -Fixture {
    BeforeAll {
        Write-Host ''
        Write-Host 'WARNING: These tests make REAL network calls. They require internet connectivity and may be slow' -ForegroundColor Yellow
        Write-Host ''
        
        # Use localhost and RFC 5737 test addresses for reliable testing
        $onlineHost = '127.0.0.1'
        $offlineHost = '192.0.2.1'  # RFC 5737 test address (unreachable)
        
        $onlineAssertion = Invoke-FastPing -HostName $onlineHost
        $offlineAssertion = Invoke-FastPing -HostName $offlineHost
    }

    Context -Name 'Default Tests' -Fixture {
        Context -Name 'Returned object properties are of the correct type' -Fixture {
            It -Name 'Has the <Property> property' -ForEach @(
                @{Property = 'HostName'; Type = 'String'}
                @{Property = 'RoundtripAverage'; Type = 'Double'}
                @{Property = 'Online'; Type = 'Boolean'}
                @{Property = 'Status'; Type = 'System.Enum'}
                @{Property = 'Sent'; Type = 'Int32'}
                @{Property = 'Received'; Type = 'Int32'}
                @{Property = 'Lost'; Type = 'Int32'}
                @{Property = 'PercentLost'; Type = 'Int32'}
                @{Property = 'Min'; Type = 'Double'}
                @{Property = 'p50'; Type = 'Double'}
                @{Property = 'p90'; Type = 'Double'}
                @{Property = 'Max'; Type = 'Double'}
                @{Property = 'RawValues'; Type = 'Int32'}
            ) -Test {
                ($onlineAssertion.$Property) | Should -BeOfType $Type
            }
        } # End Correct Properties Tests

        Context -Name 'Returns good values for an online host' -Fixture {
            It -Name 'Has the HostName property' -Test {
                $onlineAssertion.HostName | Should -BeExactly $onlineHost
            }

            It -Name 'Has the RoundtripAverage property' -Test {
                # Localhost pings may be too fast to measure (0ms) or very small
                $onlineAssertion.RoundtripAverage | Should -BeGreaterOrEqual 0
            }

            It -Name 'Has the Online property' -Test {
                $onlineAssertion.Online | Should -BeTrue
            }

            It -Name 'Has the Status property' -Test {
                $onlineAssertion.Status | Should -BeExactly 'Success'
            }
        } # End Online Host Tests

        Context -Name 'Returns good values for an offline host' -Fixture {
            It -Name 'Has the HostName property' -Test {
                $offlineAssertion.HostName | Should -BeExactly $offlineHost
            }

            It -Name 'Has the RoundtripAverage property' -Test {
                $offlineAssertion.RoundtripAverage | Should -BeNullOrEmpty
            }

            It -Name 'Has the Online property' -Test {
                $offlineAssertion.Online | Should -BeFalse
            }

            It -Name 'Has the Status property' -Test {
                # RFC 5737 test addresses may return TimedOut instead of Unknown
                $offlineAssertion.Status | Should -BeIn @('Unknown', 'TimedOut')
            }

            It -Name 'Has the PercentLost property' -Test {
                $offlineAssertion.PercentLost | Should -BeExactly 100
            }
        } # End Offline Host Tests

        Context -Name 'RoundTripAverage Values' -Fixture {
            It -Name 'Returns a RoundTripAverage of zero when the ping is too fast to average' -Test {
                $assertion = Invoke-FastPing -HostName '127.0.0.1'
                $assertion.RoundTripAverage | Should -BeGreaterOrEqual 0
                $assertion.RoundTripAverage | Should -BeLessThan 10
            }
        }

        Context -Name 'Accepts an array of HostName values' -Fixture {
            BeforeAll {
                $onlineHost = '127.0.0.1'
                $offlineHost = '192.0.2.1'  # RFC 5737 test address (unreachable)
                $assertion = Invoke-FastPing -HostName $onlineHost, $offlineHost
            }

            It -Name 'Returns the correct number of objects' -Test {
                $assertion.Count | Should -BeExactly 2
            }

            It -Name 'Returns the correct number of online objects' -Test {
                $assertion.Where( { $_.Online -eq $true }).Count | Should -BeExactly 1
            }

            It -Name 'Returns the correct number of offline objects' -Test {
                $assertion.Where( { $_.Online -ne $true }).Count | Should -BeExactly 1
            }
        }
    }

    Context -Name 'Count Tests' -Fixture {
        $testCases = @(
            @{
                Count = 2
            }
            @{
                Count = 5
            }
        )

        It -Name 'Returned <Count> results' -TestCases $testCases -Test {
            param ($Count)

            $hostName = '127.0.0.1'
            $assertion = Invoke-FastPing -HostName $hostName -Count $Count -Interval 10
            $assertion.Count | Should -BeExactly $Count
        }
    }

    Context -Name 'TimedOut Tests' -Fixture {
        $testCases = @(
            @{
                # Use RFC 5737 test address to ensure timeout
                HostName = '192.0.2.1'
                Timeout  = 500
                # RFC 5737 test addresses may return TimedOut or Unknown depending on environment
                Expected = @('Unknown', 'TimedOut')
            }
        )

        It -Name 'Returned <Expected> status' -TestCases $testCases -Test {
            param ($HostName, $Timeout, $Expected)

            $assertion = Invoke-FastPing -HostName $HostName -Timeout $Timeout -Interval 10
            $assertion.Status | Should -BeIn $Expected
        }
    }

    Context -Name 'Interval Tests' -Fixture {
        $testCases = @(
            @{
                Count                       = 3
                Interval                    = 50
                ExpectedMinimumMilliseconds = 100
            }
            @{
                Count                       = 3
                Interval                    = 200
                ExpectedMinimumMilliseconds = 350
            }
        )

        It -Name 'Execution time greater than <ExpectedMinimumMilliseconds> when Interval is <Interval>' -TestCases $testCases -Test {
            param ($Count, $Interval, $ExpectedMinimumMilliseconds)

            $timer = [System.Diagnostics.StopWatch]::StartNew()
            $null = Invoke-FastPing -HostName '127.0.0.1' -Count $count -Interval $Interval
            $timer.Stop()
            $timer.Elapsed.TotalMilliseconds | Should -BeGreaterThan $ExpectedMinimumMilliseconds
        }
    }
}