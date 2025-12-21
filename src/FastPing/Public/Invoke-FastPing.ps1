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
        $loopCounter = 0
        $loopTimer = [System.Diagnostics.Stopwatch]::new()
        $ipRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        
        # Cache DNS resolutions across iterations
        $dnsCache = @{}
    }

    process {
        try {
            while ($true) {
                $loopTimer.Restart()

                # Pre-allocate collections with known capacity
                $totalPings = $HostName.Count * $EchoRequests
                $pingObjects = [System.Collections.Generic.List[object]]::new($totalPings)
                $pingHash = @{}

                # Start async pings for each host
                foreach ($hostEntry in $HostName) {
                    if (-not $pingHash.ContainsKey($hostEntry)) {
                        $pingHash[$hostEntry] = [System.Collections.Generic.List[hashtable]]::new($EchoRequests)

                        # DNS resolution with caching
                        if ($hostEntry -notmatch $ipRegex -and -not $dnsCache.ContainsKey($hostEntry)) {
                            try {
                                $null = [System.Net.Dns]::GetHostEntry($hostEntry)
                                $dnsCache[$hostEntry] = $true
                            } catch {
                                $dnsCache[$hostEntry] = $false
                                if ($_.Exception.InnerException.Message -like '*No such host is known*' -or 
                                    $_.Exception.Message -like '*No such host is known*') {
                                    Write-Warning -Message "The HostName $hostEntry cannot be resolved."
                                }
                            }
                        }
                    }

                    for ($i = 0; $i -lt $EchoRequests; $i++) {
                        $ping = [System.Net.NetworkInformation.Ping]::new()
                        $null = $pingObjects.Add(@{
                            Host  = $hostEntry
                            Ping  = $ping
                            Task  = $ping.SendPingAsync($hostEntry, $Timeout)
                        })
                    }
                }

                # Wait for all tasks using WaitAll instead of polling
                $tasks = [System.Threading.Tasks.Task[]]($pingObjects | ForEach-Object { $_.Task })
                
                try {
                    $null = [System.Threading.Tasks.Task]::WaitAll($tasks, ($Timeout + 1000))
                } catch [System.AggregateException] {
                    # Expected for failed pings - continue processing
                }

                # Process completed results
                foreach ($pingObj in $pingObjects) {
                    try {
                        $task = $pingObj.Task
                        $hostKey = $pingObj.Host

                        if ($task.IsCompleted -and -not $task.IsFaulted) {
                            $result = $task.Result
                            $null = $pingHash[$hostKey].Add(@{
                                RoundtripTime = $result.RoundtripTime
                                Status        = $result.Status
                            })
                        } else {
                            $null = $pingHash[$hostKey].Add(@{
                                RoundtripTime = 0
                                Status        = [System.Net.NetworkInformation.IPStatus]::Unknown
                            })
                        }
                    } catch {
                        $null = $pingHash[$pingObj.Host].Add(@{
                            RoundtripTime = 0
                            Status        = [System.Net.NetworkInformation.IPStatus]::Unknown
                        })
                    } finally {
                        # Dispose ping object
                        if ($null -ne $pingObj.Ping) {
                            $pingObj.Ping.Dispose()
                        }
                    }
                }

                # Calculate results for each host
                foreach ($key in $pingHash.Keys) {
                    $hostResults = $pingHash[$key]
                    $sent = $hostResults.Count
                    $received = 0
                    $latency = [System.Collections.Generic.List[int]]::new($sent)

                    foreach ($result in $hostResults) {
                        if ($result.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                            $received++
                            $null = $latency.Add($result.RoundtripTime)
                        }
                    }

                    if ($received -ge 1) {
                        $online = $true
                        $status = [System.Net.NetworkInformation.IPStatus]::Success
                        $sortedLatency = $latency | Sort-Object
                        $roundtripAverage = [Math]::Round(($sortedLatency | Measure-Object -Average).Average, 2)
                    } else {
                        $online = $false
                        $roundtripAverage = $null

                        # Determine most common failure status
                        $statusGroups = $hostResults | Group-Object -Property Status
                        $mostCommon = $statusGroups | Sort-Object -Property Count -Descending | Select-Object -First 1
                        
                        if ($null -ne $mostCommon -and -not [string]::IsNullOrWhiteSpace($mostCommon.Name)) {
                            $status = $mostCommon.Name
                        } else {
                            $status = [System.Net.NetworkInformation.IPStatus]::Unknown
                        }
                    }

                    [FastPingResponse]::new(
                        $key,
                        $online,
                        $status,
                        $sent,
                        $received,
                        $roundtripAverage,
                        $latency.ToArray()
                    )
                }

                $loopCounter++

                if ($loopCounter -lt $Count -or $Continuous) {
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
    }
}
