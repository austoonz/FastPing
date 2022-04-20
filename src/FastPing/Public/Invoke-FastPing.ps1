<#
    .SYNOPSIS
    Performs a series of asynchronous pings against a set of target hosts.

    .DESCRIPTION
    This function uses the System.Net.Networkinformation.Ping object to perform a series of asynchronous pings against a set of target hosts.
    Each ping result is calculated the specified number of echo requests.

    .PARAMETER HostName
    String array of target hosts.

    .PARAMETER Count
    Number of ping requests to send. Aliased with 'n', like ping.exe.

    .PARAMETER Continuous
    Enables continuous pings against the target hosts. Stop with CTRL+C. Aliases with 't', like ping.exe.

    .PARAMETER Timeout
    Timeout in milliseconds to wait for each reply. Defaults to 2 seconds (5000 ms). Aliased with 'w', like ping.exe.

    Per MSDN Documentation, "When specifying very small numbers for timeout, the Ping reply can be received even if timeout milliseconds have elapsed." (https://msdn.microsoft.com/en-us/library/ms144955.aspx).

    .PARAMETER Interval
    Number of milliseconds between ping requests.

    .PARAMETER EchoRequests
    Number of echo requests to use for each ping result. Used to generate the calculated output fields. Defaults to 4.

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io'

    HostName         Online Status     p90   PercentLost
    --------         ------ ------     ---   -----------
    andrewpearce.io  True   Success    4     0

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io','doesnotexist.andrewpearce.io'

    HostName         Online Status     p90   PercentLost
    --------         ------ ------     ---   -----------
    andrewpearce.io  True   Success    5     0
    doesnotexist.an… False  Unknown          100

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io' -Count 5

    This example generates five ping results against the host 'andrewpearce.io'.

    .EXAMPLE
    fp andrewpearce.io -n 5

    This example pings the host 'andrewpearce.io' five times using syntax similar to ping.exe.

    .EXAMPLE
    Invoke-FastPing -HostName 'microsoft.com' -Timeout 500

    This example pings the host 'microsoft.com' with a 500 millisecond timeout.

    .EXAMPLE
    fp microsoft.com -w 500

    This example pings the host 'microsoft.com' with a 500 millisecond timeout using syntax similar to ping.exe.

    .EXAMPLE
    fp andrewpearce.io -Continuous

    This example pings the host 'andrewpearce.io' continuously until CTRL+C is used.

    .EXAMPLE
    fp andrewpearce.io -t

    This example pings the host 'andrewpearce.io' continuously until CTRL+C is used.
#>
function Invoke-FastPing {
    [CmdletBinding(DefaultParameterSetName = 'Count')]
    [Alias('FastPing', 'fping', 'fp')]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Computer', 'ComputerName', 'Host')]
        [String[]] $HostName,

        [Parameter(ParameterSetName = 'Count')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Alias('N')]
        [Int] $Count = 1,

        [Parameter(ParameterSetName = 'Continuous')]
        [Alias('T')]
        [Switch] $Continuous,

        [ValidateRange(1, [Int]::MaxValue)]
        [Alias('W')]
        [Int] $Timeout = 5000,

        [ValidateRange(1, [Int]::MaxValue)]
        [Int] $Interval = 1000,

        [ValidateRange(1, [Int]::MaxValue)]
        [Alias('RoundtripAveragePingCount')]
        [Int] $EchoRequests = 4
    )

    begin {
        # The time used for the ping async wait() method
        $asyncWaitMilliseconds = 500

        # Used to control the Count of echo requests
        $loopCounter = 0

        # Used to control the Interval between echo requests
        $loopTimer = [System.Diagnostics.Stopwatch]::new()

        # Regex for identifying an IPv4 address
        $ipRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

        # Used to shorten line length when filtering results
        $sortCount = @{
            Property   = 'Count'
            Descending = $true
        }
    }

    process {
        try {
            while ($true) {
                $loopTimer.Restart()

                # Objects to hold items as we process pings
                $queue = [System.Collections.Queue]::new()
                $pingHash = @{}

                # Start an asynchronous ping against each computer
                foreach ($hn in $HostName) {
                    if ($pingHash.Keys -notcontains $hn) {
                        $pingHash.Add($hn, [System.Collections.ArrayList]::new())

                        # Attempt to resolve the hostname to prevent issues where the first host fails to resolve
                        if ($hn -notmatch $ipRegex) {
                            try {
                                $null = [System.Net.Dns]::Resolve($hn)
                            } catch {
                                if ($_.Exception.Message -like '*No such host is known*') {
                                    Write-Warning "The HostName $hn cannot be resolved."
                                }
                            }
                        }
                    }

                    for ($i = 0; $i -lt $EchoRequests; $i++) {
                        $ping = [System.Net.Networkinformation.Ping]::new()
                        $object = @{
                            Host  = $hn
                            Ping  = $ping
                            Async = $ping.SendPingAsync($hn, $Timeout)
                        }
                        $queue.Enqueue($object)
                    }
                }

                # Process the asynchronous pings
                while ($queue.Count -gt 0) {
                    $object = $queue.Dequeue()

                    try {
                        # Wait for completion
                        if ($object.Async.Wait($asyncWaitMilliseconds) -eq $true) {
                            [Void]$pingHash[$object.Host].Add(@{
                                    Host          = $object.Host
                                    RoundtripTime = $object.Async.Result.RoundtripTime
                                    Status        = $object.Async.Result.Status
                                })
                            continue
                        }
                    } catch {
                        # The Wait() method can throw an exception if the host does not exist.
                        if ($object.Async.IsCompleted -eq $true) {
                            [Void]$pingHash[$object.Host].Add(@{
                                    Host          = $object.Host
                                    RoundtripTime = $object.Async.Result.RoundtripTime
                                    Status        = $object.Async.Result.Status
                                })
                            continue
                        } else {
                            Write-Warning -Message ('Unhandled exception: {0}' -f $_.Exception.Message)
                        }
                    }

                    $queue.Enqueue($object)
                }

                # Using the ping results in pingHash, calculate the average RoundtripTime
                foreach ($key in $pingHash.Keys) {
                    $pingStatus = $pingHash.$key.Status | Select-Object -Unique

                    $unsuccessfulPingStatus = $pingStatus | Where-Object {$_ -ne [System.Net.NetworkInformation.IPStatus]::Success}

                    $sent = 0
                    $received = 0
                    $latency = [System.Collections.ArrayList]::new()
                    foreach ($value in $pingHash.$key) {
                        $sent++
                        if (-not([String]::IsNullOrWhiteSpace($value.RoundtripTime)) -and $value.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $received++
                            [Void]$latency.Add($value.RoundtripTime)
                        }
                    }

                    $sortedLatency = $latency | Sort-Object

                    if ($received -ge 1) {
                        $online = $true
                        $status = [System.Net.NetworkInformation.IPStatus]::Success

                        $roundtripAverage = [Math]::Round(($sortedLatency | Measure-Object -Average).Average, 2)
                    } else {
                        $online = $false

                        if ($unsuccessfulPingStatus.Count -eq 1) {
                            $status = $pingStatus
                        } else {
                            $groupedPingStatus = $pingHash.$key.Status | Group-Object
                            $status = ($groupedPingStatus | Sort-Object @sortCount | Select-Object -First 1).Name
                        }

                        if ([String]::IsNullOrWhiteSpace($status)) {
                            $status = [System.Net.NetworkInformation.IPStatus]::Unknown
                        }

                        $roundtripAverage = $null
                    }

                    [FastPingResponse]::new(
                        $key,
                        $online,
                        $status,
                        $sent,
                        $received,
                        $roundtripAverage,
                        $latency
                    )
                } # End result processing

                # Increment the loop counter
                $loopCounter++

                if ($loopCounter -lt $Count -or $Continuous -eq $true) {
                    $timeToSleep = $Interval - $loopTimer.Elapsed.TotalMilliseconds
                    if ($timeToSleep -gt 0) {
                        Start-Sleep -Milliseconds $timeToSleep
                    }
                } else {
                    break
                }
            }
        } catch {
            throw
        } finally {
            $loopTimer.Stop()
        }

    } # End Process
}