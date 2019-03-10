<#
    .SYNOPSIS
    Performs a series of asynchronous pings against a set of target hosts.

    .DESCRIPTION
    This function uses System.Net.Networkinformation.Ping object to perform
    a series of asynchronous pings against a set of target hosts.

    .PARAMETER HostName
    String array of target hosts.

    .PARAMETER Count
    Number of echo requests to send. Aliased with 'n', like ping.exe.

    .PARAMETER Timeout
    Timeout in milliseconds to wait for each reply. Defaults to 2 seconds (5000). Aliased with 'w', like ping.exe.

    Per MSDN Documentation, "When specifying very small numbers for timeout, the Ping reply can be received even if timeout milliseconds have elapsed." (https://msdn.microsoft.com/en-us/library/ms144955.aspx).

    .PARAMETER Interval
    Number of milliseconds between echo requests.

    .PARAMETER RoundtripAveragePingCount
    Number of echo requests to send for calculating the Roundtrip average. Defaults to 4.

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io'

    HostName        RoundtripAverage Online
    --------        ---------------- ------
    andrewpearce.io               22   True

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io','doesnotexist.andrewpearce.io'

    HostName                     RoundtripAverage Online
    --------                     ---------------- ------
    doesnotexist.andrewpearce.io                   False
    andrewpearce.io              22                 True

    .EXAMPLE
    Invoke-FastPing -HostName 'andrewpearce.io' -Count 5

    This example pings the host 'andrewpearce.io' five times.

    .EXAMPLE
    fp andrewpearce.io -n 5

    This example pings the host 'andrewpearce.io' five times using syntax similar to ping.exe.

    .EXAMPLE
    Invoke-FastPing -HostName 'microsoft.com' -Timeout 500

    This example pings the host 'microsoft.com' with a 500 millisecond timeout.

    .EXAMPLE
    fp microsoft.com -w 500

    This example pings the host 'microsoft.com' with a 500 millisecond timeout using syntax similar to ping.exe.
#>
function Invoke-FastPing
{
    [alias('FastPing', 'fping', 'fp')]
    param
    (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Computer', 'ComputerName', 'Host')]
        [String[]] $HostName,

        [ValidateRange(1, [Int]::MaxValue)]
        [Alias('N')]
        [Int] $Count = 1,

        [ValidateRange(1, [Int]::MaxValue)]
        [Alias('W')]
        [Int] $Timeout = 5000,

        [ValidateRange(1, [Int]::MaxValue)]
        [Int] $Interval = 1000,

        [ValidateRange(1, [Int]::MaxValue)]
        [Int] $RoundtripAveragePingCount = 4
    )

    begin
    {
        # The time used for the ping asyns wait() method
        $asyncWaitMilliseconds = 500

        # Used to control the Count of echo requests
        $loopCounter = 0

        # Used to control the Interval between echo requests
        $loopTimer = [System.Diagnostics.Stopwatch]::new()
    }

    process
    {
        try
        {
            while ($true)
            {
                $loopTimer.Restart()

                # Objects to hold items as we process pings
                $queue = [System.Collections.Queue]::new()
                $pingHash = @{}

                # Start an asynchronous ping against each computer
                foreach ($hn in $HostName)
                {
                    if ($pingHash.Keys -notcontains $hn)
                    {
                        $pingHash.Add($hn, [System.Collections.ArrayList]::new())
                    }

                    for ($i = 0; $i -lt $RoundtripAveragePingCount; $i++)
                    {
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
                while ($queue.Count -gt 0)
                {
                    $object = $queue.Dequeue()

                    try
                    {
                        # Wait for completion
                        if ($object.Async.Wait($asyncWaitMilliseconds) -eq $true)
                        {
                            [Void]$pingHash[$object.Host].Add(@{
                                    Host          = $object.Host
                                    RoundtripTime = $object.Async.Result.RoundtripTime
                                    Status        = $object.Async.Result.Status
                                })
                            continue
                        }
                    }
                    catch
                    {
                        # The Wait() method can throw an exception if the host does not exist.
                        if ($object.Async.IsCompleted -eq $true)
                        {
                            [Void]$pingHash[$object.Host].Add(@{
                                    Host          = $object.Host
                                    RoundtripTime = $object.Async.Result.RoundtripTime
                                    Status        = $object.Async.Result.Status
                                })
                            continue
                        }
                        else
                        {
                            Write-Warning -Message ('Unhandled exception: {0}' -f $_.Exception.Message)
                        }
                    }

                    $queue.Enqueue($object)
                }

                # Using the ping results in pingHash, calculate the average RoundtripTime
                foreach ($key in $pingHash.Keys)
                {
                    $pingStatus = $pingHash.$key.Status | Select-Object -Unique

                    if ($pingStatus -eq [System.Net.NetworkInformation.IPStatus]::Success)
                    {
                        $online = $true
                        $status = [System.Net.NetworkInformation.IPStatus]::Success
                    }
                    elseif ($pingStatus.Count -eq 1)
                    {
                        $online = $false
                        $status = $pingStatus
                    }
                    else
                    {
                        $online = $false
                        $status = [System.Net.NetworkInformation.IPStatus]::Unknown
                    }

                    if ($online -eq $true)
                    {
                        $latency = [System.Collections.ArrayList]::new()
                        foreach ($value in $pingHash.$key)
                        {
                            if (-not([String]::IsNullOrWhiteSpace($value.RoundtripTime)))
                            {
                                [Void]$latency.Add($value.RoundtripTime)
                            }
                        }

                        $measuredLatency = $latency | Measure-Object -Average -Sum
                        if ($measuredLatency.Average)
                        {
                            $roundtripAverage = [Math]::Round($measuredLatency.Average, 0)
                        }
                        elseif ($measuredLatency.Sum -eq 0)
                        {
                            $roundtripAverage = 0
                        }
                        else
                        {
                            $roundtripAverage = $null
                        }
                    }
                    else
                    {
                        $roundtripAverage = $null
                    }

                    [FastPingResponse]::new(
                        $key,
                        $roundtripAverage,
                        $online,
                        $status
                    )
                } # End result processing

                # Increment the loop counter
                $loopCounter++

                if ($loopCounter -lt $Count)
                {
                    $timeToSleep = $Interval - $loopTimer.Elapsed.TotalMilliseconds
                    if ($timeToSleep -gt 0)
                    {
                        Start-Sleep -Milliseconds $timeToSleep
                    }
                }
                else
                {
                    break
                }
            }
        }
        catch
        {
            throw
        }
        finally
        {
            $loopTimer.Stop()
        }

    } # End Process
}