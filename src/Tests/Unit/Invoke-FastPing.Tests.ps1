$global:WarningPreference = 'SilentlyContinue'
Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

Describe -Name 'Invoke-FastPing' -Fixture {

    Context -Name 'Default Tests' -Fixture {
        $onlineHost = 'andrewpearce.io'
        $onlineAssertion = Invoke-FastPing -HostName $onlineHost

        $offlineHost = 'doesnotexist.andrewpearce.io'
        $offlineAssertion = Invoke-FastPing -HostName $offlineHost

        Context -Name 'Returned object properties are of the correct type' -Fixture {
            It -Name 'Has the HostName String property' -Test {
                $onlineAssertion.HostName | Should -BeOfType 'String'
            }

            It -Name 'Has the RoundtripAverage Boolean property' -Test {
                $onlineAssertion.RoundtripAverage | Should -BeOfType 'Double'
            }

            It -Name 'Has the Online Boolean property' -Test {
                $onlineAssertion.Online | Should -BeOfType 'Boolean'
            }
        } # End Correct Properties Tests

        Context -Name 'Returns good values for an online host' -Fixture {
            It -Name 'Has the HostName String property' -Test {
                $onlineAssertion.HostName | Should -BeExactly $onlineHost
            }

            It -Name 'Has the RoundtripAverage Boolean property' -Test {
                $onlineAssertion.RoundtripAverage | Should -BeGreaterThan 0
            }

            It -Name 'Has the Online Boolean property' -Test {
                $onlineAssertion.Online | Should -BeTrue
            }
        } # End Online Host Tests

        Context -Name 'Returns good values for an offline host' -Fixture {
            It -Name 'Has the HostName String property' -Test {
                $offlineAssertion.HostName | Should -BeExactly $offlineHost
            }

            It -Name 'Has the RoundtripAverage Boolean property' -Test {
                $offlineAssertion.RoundtripAverage | Should -BeNullOrEmpty
            }

            It -Name 'Has the Online Boolean property' -Test {
                $offlineAssertion.Online | Should -BeFalse
            }
        } # End Offline Host Tests

        Context -Name 'RoundTripAverage Values' -Fixture {
            It -Name 'Returns a RoundTripAverage of zero when the ping is too fast to average' -Test {
                $assertion = Invoke-FastPing -HostName '127.0.0.1'
                $assertion.RoundTripAverage | Should -BeExactly 0
            }
        }

        Context -Name 'Accepts an array of HostName values' -Fixture {
            $onlineHost = 'andrewpearce.io'
            $offlineHost = 'doesnotexist.andrewpearce.io'
            $assertion = Invoke-FastPing -HostName $onlineHost, $offlineHost

            It -Name 'Returns the correct number of objects' -Test {
                $assertion.Count | Should -BeExactly 2
            }

            It -Name 'Returns the correct number of online objects' -Test {
                $assertion.Where( {$_.Online -eq $true}).Count | Should -BeExactly 1
            }

            It -Name 'Returns the correct number of offline objects' -Test {
                $assertion.Where( {$_.Online -ne $true}).Count | Should -BeExactly 1
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

            $hostName = '1.1.1.1'
            $assertion = Invoke-FastPing -HostName $hostName -Count $Count -Interval 10
            $assertion.Count | Should -BeExactly $Count
        }
    }

    Context -Name 'TimedOut Tests' -Fixture {
        $testCases = @(
            @{
                # As at 2019-03-03, microsoft.com does not respond to echo requests
                HostName = 'microsoft.com'
                Timeout  = 500
                Expected = 'TimedOut'
            }
        )

        It -Name 'Returned <Expected> status' -TestCases $testCases -Test {
            param ($HostName, $Timeout, $Expected)

            $assertion = Invoke-FastPing -HostName $HostName -Timeout $Timeout -Interval 10
            $assertion.Status | Should -BeExactly $Expected
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
                ExpectedMinimumMilliseconds = 400
            }
        )

        It -Name 'Execution time greated than <ExpectedMinimumMilliseconds> when Interval is <Interval>' -TestCases $testCases -Test {
            param ($Count, $Interval, $ExpectedMinimumMilliseconds)

            $timer = [System.Diagnostics.StopWatch]::StartNew()
            $null = Invoke-FastPing -HostName '127.0.0.1' -Count $count -Interval $Interval
            $timer.Stop()
            $timer.Elapsed.TotalMilliseconds | Should -BeGreaterThan $ExpectedMinimumMilliseconds
        }
    }
}