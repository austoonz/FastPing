# FastPing

[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/FastPing.svg)](https://www.powershellgallery.com/packages/FastPing)

A PowerShell module that can help speed up ping requests against a fleet of target hosts.

## Overview

FastPing provides high-performance ping operations for PowerShell, enabling you to quickly test connectivity to multiple hosts simultaneously. Built for speed and efficiency, it handles:

- Fast ICMP ping operations
- Parallel ping requests to multiple hosts
- Network sweep operations across IP ranges
- Subnet-based ping sweeps

## Installation

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/FastPing):

```powershell
# Install for current user
Install-Module -Name FastPing -Scope CurrentUser

# Install for all users (requires admin)
Install-Module -Name FastPing -Scope AllUsers
```

## Quick Start

### Invoke-FastPing

```powershell
# Ping 1.1.1.1 using the function name
Invoke-FastPing -HostName '1.1.1.1'

# Ping 1.1.1.1 using the fp alias
fp 1.1.1.1

# Ping some DNS resolvers using the fp alias
fp 1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4

# Ping some DNS resolvers using the fp alias using 50 pings per host
fp 1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4 -Count 50
```

### Invoke-PingSweep

```powershell
# Ping a range of IP Addresses using the function name
Invoke-PingSweep -StartIP '1.1.1.1' -EndIP '1.1.1.5'

# Ping a range of IP Addresses using the psweep alias
psweep -StartIP '1.1.1.1' -EndIP '1.1.1.5'

# Ping a range of IP Addresses using the psweep alias and subnet calculations
psweep -IPAddress '1.1.1.1' -SubnetMask '255.255.255.252'
```

## Functions

| Function | Description |
|----------|-------------|
| [Invoke-FastPing](functions/Invoke-FastPing.md) | Performs fast ICMP ping operations against one or more hosts |
| [Invoke-PingSweep](functions/Invoke-PingSweep.md) | Performs ping sweep operations across IP address ranges |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7.x
- Supported platforms: Windows, Linux, macOS

## Performance

FastPing uses parallel processing to significantly speed up ping operations when testing multiple hosts, making it ideal for:

- Network discovery and mapping
- Availability monitoring
- Quick connectivity checks across large IP ranges
- Infrastructure health checks

## Contributing

Contributions are welcome! Please see the [repository](https://github.com/austoonz/FastPing) for details.

```powershell
# Clone the repository
git clone https://github.com/austoonz/FastPing.git
cd FastPing

# Install dependencies
.\install_modules.ps1

# Build the module
.\build.ps1 -Build

# Run tests
.\build.ps1 -Test
```

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/austoonz/FastPing/blob/main/LICENSE) file for details.

## Author

[Andrew Pearce](https://twitter.com/austoonz) - [https://andrewpearce.io](https://andrewpearce.io)

## Contributors

- [Jake Morrison](https://twitter.com/JakeMorrison) - CI/CD standardization work
- [Chris Dent](http://www.indented.co.uk/) - Network Calculation PowerShell code from the [Indented.Net.IP](https://www.powershellgallery.com/packages/Indented.Net.IP/) PowerShell Module
