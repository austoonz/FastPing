<#
    .SYNOPSIS
    Converts a Decimal IP address into a 32-bit unsigned integer.

    .DESCRIPTION
    ConvertToDecimalIP takes a decimal IP, uses a shift operation on each octet and returns a single UInt32 value.

    .INPUTS
    System.Net.IPAddress

    .EXAMPLE
    ConvertToDecimalIP 1.2.3.4

    Converts an IP address to an unsigned 32-bit integer value.

    .NOTES
    This code is copied from the Indented.Net.IP module (https://github.com/indented-automation/Indented.Net.IP).
    The copy is due to not wanting to take a dependency, and that module licensed with a permissive license.
    Thanks Chris Dent!
#>
function ConvertToDecimalIP {
    [CmdletBinding()]
    [OutputType([UInt32])]
    param (
        # An IP Address to convert.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline )]
        [IPAddress] $IPAddress
    )

    process {
        [UInt32]([IPAddress]::HostToNetworkOrder($IPAddress.Address) -shr 32 -band [UInt32]::MaxValue)
    }
}