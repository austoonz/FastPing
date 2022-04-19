<#
    .SYNOPSIS
    Get a list of IP addresses within the specified network.

    .DESCRIPTION
    GetNetworkRange finds the network and broadcast address as decimal values then starts a counter between the two, returning IPAddress for each.

    .INPUTS
    System.String

    .EXAMPLE
    GetNetworkRange 192.168.0.0 255.255.255.0

    Returns all IP addresses in the range 192.168.0.0/24.

    .EXAMPLE
    GetNetworkRange 10.0.8.0/22

    Returns all IP addresses in the range 192.168.0.0 255.255.252.0.

    .NOTES
    This code is copied from the Indented.Net.IP module (https://github.com/indented-automation/Indented.Net.IP).
    The copy is due to not wanting to take a dependency, and that module licensed with a permissive license.
    Thanks Chris Dent!
#>
function GetNetworkRange {
    [CmdletBinding(DefaultParameterSetName = 'FromIPAndMask')]
    [OutputType([IPAddress])]
    param (
        # Either a literal IP address, a network range expressed as CIDR notation, or an IP address and subnet mask in a string.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ParameterSetName = 'FromIPAndMask')]
        [String] $IPAddress,

        # A subnet mask as an IP address.
        [Parameter(Position = 2, ParameterSetName = 'FromIPAndMask')]
        [String] $SubnetMask,

        # Include the network and broadcast addresses when generating a network address range.
        [Parameter(ParameterSetName = 'FromIPAndMask')]
        [Switch] $IncludeNetworkAndBroadcast,

        # The start address of a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress] $StartIPAddress,

        # The end address of a range.
        [Parameter(Mandatory, ParameterSetName = 'FromStartAndEnd')]
        [IPAddress] $EndIPAddress
    )

    process {
        if ($pscmdlet.ParameterSetName -eq 'FromIPAndMask') {
            try {
                $null = $psboundparameters.Remove('IncludeNetworkAndBroadcast')
                $network = ConvertToNetwork @psboundparameters
            } catch {
                $pscmdlet.ThrowTerminatingError($_)
            }

            $decimalIP = ConvertToDecimalIP -IPAddress $network.IPAddress
            $decimalMask = ConvertToDecimalIP -IPAddress $network.SubnetMask

            $startDecimal = $decimalIP -band $decimalMask
            $endDecimal = $decimalIP -bor (-bnot $decimalMask -band [UInt32]::MaxValue)

            if (-not $IncludeNetworkAndBroadcast) {
                $startDecimal++
                $endDecimal--
            }
        } else {
            $startDecimal = ConvertToDecimalIP -IPAddress $StartIPAddress
            $endDecimal = ConvertToDecimalIP -IPAddress $EndIPAddress
        }

        for ($i = $startDecimal; $i -le $endDecimal; $i++) {
            [IPAddress]([IPAddress]::NetworkToHostOrder([Int64]$i) -shr 32 -band [UInt32]::MaxValue)
        }
    }
}