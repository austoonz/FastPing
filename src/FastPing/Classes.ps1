class FastPingResponse {
    [String] $HostName
    [Nullable[Double]] $RoundtripAverage
    [Boolean] $Online
    [System.Net.NetworkInformation.IPStatus] $Status

    hidden [System.Version] $HostNameAsVersion

    hidden [string]$IPRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

    FastPingResponse(
        [String] $HostName,
        [Nullable[Double]] $RoundtripAverage,
        [Boolean] $Online,
        [System.Net.NetworkInformation.IPStatus] $Status
    ) {
        $this.HostName = $HostName
        if ($null -ne $RoundtripAverage) {
            $this.RoundtripAverage = $RoundtripAverage
        }
        $this.Online = $Online
        $this.Status = $Status

        if ($HostName -match $this.IPRegex) {
            $this.HostNameAsVersion = $HostName
        }
    }
}