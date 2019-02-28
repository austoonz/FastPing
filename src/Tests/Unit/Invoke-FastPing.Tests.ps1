Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

Describe -Name $ModuleName -Fixture {

    $function = 'Invoke-FastPing'
    Context -Name $function -Fixture {

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

        Context -Name 'Accepts an array of HostName values' -Fixture {
            $assertion = Invoke-FastPing -HostName $onlineHost,$offlineHost

            It -Name 'Returns the correct number of objects' -Test {
                $assertion.Count | Should -BeExactly 2
            }

            It -Name 'Returns the correct number of online objects' -Test {
                $assertion.Where({$_.Online -eq $true}).Count | Should -BeExactly 1
            }

            It -Name 'Returns the correct number of offline objects' -Test {
                $assertion.Where({$_.Online -ne $true}).Count | Should -BeExactly 1
            }
        }
    }
}