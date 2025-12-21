class FastPingResponse {
    [String] $HostName
    [Boolean] $Online
    [System.Net.NetworkInformation.IPStatus] $Status
    [int] $Sent
    [int] $Received
    [int] $Lost
    [int] $PercentLost
    [Nullable[Double]] $Min
    [Nullable[Double]] $p50
    [Nullable[Double]] $p90
    [Nullable[Double]] $Max
    [int[]] $RawValues

    hidden [Nullable[Double]] $RoundtripAverage
    hidden [System.Version] $HostNameAsVersion

    hidden [string]$IPRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

    FastPingResponse(
        [String] $HostName,
        [Boolean] $Online,
        [System.Net.NetworkInformation.IPStatus] $Status,
        [int] $Sent,
        [int] $Received,
        [Nullable[Double]] $RoundtripAverage,
        [int[]]$RawValues
    ) {
        $this.HostName = $HostName
        $this.Online = $Online
        $this.Status = $Status

        $this.RoundtripAverage = $RoundtripAverage

        $this.Sent = $Sent
        $this.Received = $Received
        $this.Lost = $this.Sent - $this.Received
        $this.PercentLost = $this.Lost / $this.Sent * 100

        $this.RawValues = $RawValues

        if ($HostName -match $this.IPRegex) {
            $this.HostNameAsVersion = $HostName
        }

        $sortedLatency = $this.RawValues | Sort-Object
        $this.Min = $sortedLatency | Select-Object -First 1
        $this.p50 = $sortedLatency | Select-Object -First 1 -Skip ([Math]::Floor($this.RawValues.Count * .5))
        $this.p90 = $sortedLatency | Select-Object -First 1 -Skip ([Math]::Floor($this.RawValues.Count * .9))
        $this.Max = $sortedLatency | Select-Object -Last 1
    }
}