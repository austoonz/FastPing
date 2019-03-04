class FastPingResponse
{
    [String] $HostName
    [Nullable[Double]] $RoundtripAverage
    [Boolean] $Online
    [System.Net.NetworkInformation.IPStatus] $Status

    FastPingResponse(
        [String] $HostName,
        [Nullable[Double]] $RoundtripAverage,
        [Boolean] $Online,
        [System.Net.NetworkInformation.IPStatus] $Status
    )
    {
        $this.HostName = $HostName
        if ($null -ne $RoundtripAverage)
        {
            $this.RoundtripAverage = $RoundtripAverage
        }
        $this.Online = $Online
        $this.Status = $Status
    }
}