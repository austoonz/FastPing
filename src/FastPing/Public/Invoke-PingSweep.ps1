<#
    .SYNOPSIS
    Performs a ping sweep against a series of target IP Addresses.

    .DESCRIPTION
    This function calculates the list of IP Addresses to target, and wraps
    a call to Invoke-FastPingto perform the ping sweep.

    .PARAMETER StartIP
    The IP Address to start from.

    .PARAMETER EndIp
    The IP Address to finish with.

    .PARAMETER IPAddress
    An IP Address, to be matched with an appropriate Subnet Mask.

    .PARAMETER SubnetMask
    A Subnet Mask for network range calculations.

    .EXAMPLE
    Invoke-PingSweep -StartIP '1.1.1.1' -EndIP '1.1.1.5'

    HostName RoundtripAverage Online  Status
    -------- ---------------- ------  ------
    1.1.1.3                19   True Success
    1.1.1.4                22   True Success
    1.1.1.1                21   True Success
    1.1.1.2                19   True Success
    1.1.1.5                24   True Success

    .EXAMPLE
    Invoke-PingSweep -IPAddress '1.1.1.1' -SubnetMask '255.255.255.252'

    HostName RoundtripAverage Online  Status
    -------- ---------------- ------  ------
    1.1.1.2                21   True Success
    1.1.1.1                16   True Success
#>
function Invoke-PingSweep {
    [CmdletBinding(DefaultParameterSetName = 'FromStartAndEnd')]
    [Alias('PingSweep', 'psweep')]
    param
    (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'FromStartAndEnd')]
        [ValidateScript( { [System.Net.IPAddress]$_ } )]
        [String] $StartIP,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'FromStartAndEnd')]
        [ValidateScript( { [System.Net.IPAddress]$_ } )]
        [String] $EndIP,

        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'FromIPAndMask')]
        [ValidateScript( { [System.Net.IPAddress]$_ } )]
        [String] $IPAddress,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'FromIPAndMask')]
        [ValidateScript( { [System.Net.IPAddress]$_ } )]
        [String] $SubnetMask,

        [Switch] $ReturnOnlineOnly
    )

    switch ($PSCmdlet.ParameterSetName) {
        'FromIPAndMask' {
            $getNetworkRange = @{
                IPAddress  = $IPAddress
                SubnetMask = $SubnetMask
            }
        }
        'FromStartAndEnd' {
            $getNetworkRange = @{
                StartIPAddress = $StartIP
                EndIPAddress   = $EndIP
            }
        }
    }

    $networkRange = (GetNetworkRange @getNetworkRange).IPAddressToString
    if ($ReturnOnlineOnly) {
        $whereObject = { $_.Online -eq $true }
        Invoke-FastPing -HostName $networkRange | Where-Object $whereObject | Sort-Object -Property HostNameAsVersion
    } else {
        Invoke-FastPing -HostName $networkRange | Sort-Object -Property HostNameAsVersion
    }
}