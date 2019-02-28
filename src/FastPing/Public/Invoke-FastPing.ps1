<#
    .SYNOPSIS
    Performs a series of asynchronous pings against a set of target hosts.

    .DESCRIPTION
    This function uses System.Net.Networkinformation.Ping object to perform
    a series of asynchronous pings against a set of target hosts.

    .PARAMETER HostName
    A string array of target hosts to ping.

    .PARAMETER RoundtripAveragePingCount
    The number of pings to send against each host for calculating the Roundtrip average. Defaults to 4.

    .PARAMETER WaitTimeMilliseconds
    The time in milliseconds to wait for each ping to complete. Defaults to 500.

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

        [Int] $RoundtripAveragePingCount = 4,

        [Int] $WaitTimeMilliseconds = 500
    )

    process
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
                if ($object.Async.Wait($WaitTimeMilliseconds) -eq $true)
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

    } # End Process
}