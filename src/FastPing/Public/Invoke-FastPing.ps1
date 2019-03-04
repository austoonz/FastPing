<#
    .SYNOPSIS
    Performs a series of asynchronous pings against a set of target hosts.

    .DESCRIPTION
    This function uses System.Net.Networkinformation.Ping object to perform
    a series of asynchronous pings against a set of target hosts.

    .PARAMETER HostName
    A string array of target hosts.

    .PARAMETER Count
    The number of echo requests to send.

    .PARAMETER RoundtripAveragePingCount
    The number of echo requests to send for calculating the Roundtrip average. Defaults to 4.

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

        [Int] $RoundtripAveragePingCount = 4
    )

    begin
    {
        $loopCounter = 0
        $internalWaitTimeMilliseconds = 500
    }

    process
    {
        while ($loopCounter -lt $Count)
        {
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
                        Async = $ping.SendPingAsync($hn)
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
                    if ($object.Async.Wait($internalWaitTimeMilliseconds) -eq $true)
                    {
                        [Void]$pingHash[$object.Host].Add(@{
                                Host          = $object.Host
                                RoundtripTime = $object.Async.Result.RoundtripTime
                                Status        = $object.Async.Status
                            })
                        continue
                    }
                }
                catch
                {
                    if ($object.Async.IsCompleted -eq $true)
                    {
                        [Void]$pingHash[$object.Host].Add(@{
                                Host          = $object.Host
                                RoundtripTime = $object.Async.Result.RoundtripTime
                                Status        = $object.Async.Status
                            })
                        continue
                    }
                    else
                    {
                        Write-Warning -Message $_.Exception.Message
                    }
                }

                $queue.Enqueue($object)
            }

            # Using the ping results in pingHash, calculate the average RoundtripTime
            foreach ($key in $pingHash.Keys)
            {
                if (($pingHash.$key.Status | Select-Object -Unique) -eq 'RanToCompletion')
                {
                    $online = $true
                }
                else
                {
                    $online = $false
                }

                if ($online -eq $true)
                {
                    $latency = [System.Collections.ArrayList]::new()
                    foreach ($value in $pingHash.$key)
                    {
                        if ($value.RoundtripTime)
                        {
                            [Void]$latency.Add($value.RoundtripTime)
                        }
                    }

                    $average = $latency | Measure-Object -Average
                    if ($average.Average)
                    {
                        $roundtripAverage = [Math]::Round($average.Average, 0)
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

                [PSCustomObject]@{
                    HostName         = $key
                    RoundtripAverage = $roundtripAverage
                    Online           = $online
                }
            } # End result processing

            # Increment the loop counter
            $loopCounter++
        }

    } # End Process
}