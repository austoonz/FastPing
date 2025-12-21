# FastPing

[![Minimum Supported PowerShell Version][powershell-minimum]][powershell-github]
[![PowerShell Gallery][psgallery-img]][psgallery-site]

[powershell-minimum]: https://img.shields.io/badge/PowerShell-5.1+-blue.svg
[powershell-github]:  https://github.com/PowerShell/PowerShell
[psgallery-img]:      https://img.shields.io/powershellgallery/dt/FastPing.svg
[psgallery-site]:     https://www.powershellgallery.com/packages/FastPing

Branch | Windows | Linux |
--- | --- | --- |
master | ![Build Status][master-windows] | ![Build Status][master-linux] |
development | ![Build Status][development-windows] | ![Build Status][development-linux] |

[master-windows]:        https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiMkpSVnUrNFQzU1BvWlFTUzJFaUZlRnRwTmtRSzRjYXdncjRHZ1E3WHNYTGJiWURMRGFEQWJYbk42allBUVBCMVRsRHhYcWh1NFR0M24yOXRVNVY1ZVd3PSIsIml2UGFyYW1ldGVyU3BlYyI6InBSK096RWlJL2Vwd2w1SWsiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master
[master-linux]:          https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiU0pvako5QzMzZkpzUi9Ndk5PWVdEbzZuRjM1TnZlR0JMSWNKTmR4Ky8xeCtwSWNyV3hHRGtqTXRiRTFud1B4UlZ1bnhGZ01PZy9OaXhlL1plVWdQdnpnPSIsIml2UGFyYW1ldGVyU3BlYyI6IlgraytsdU42UjFPTU0wV0YiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master
[development-windows]:   https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiMkpSVnUrNFQzU1BvWlFTUzJFaUZlRnRwTmtRSzRjYXdncjRHZ1E3WHNYTGJiWURMRGFEQWJYbk42allBUVBCMVRsRHhYcWh1NFR0M24yOXRVNVY1ZVd3PSIsIml2UGFyYW1ldGVyU3BlYyI6InBSK096RWlJL2Vwd2w1SWsiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=development
[development-linux]:     https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiU0pvako5QzMzZkpzUi9Ndk5PWVdEbzZuRjM1TnZlR0JMSWNKTmR4Ky8xeCtwSWNyV3hHRGtqTXRiRTFud1B4UlZ1bnhGZ01PZy9OaXhlL1plVWdQdnpnPSIsIml2UGFyYW1ldGVyU3BlYyI6IlgraytsdU42UjFPTU0wV0YiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=development


## Synopsis

FastPing is a PowerShell Module that can help speed up ping requests against a fleet of target hosts.

## Installation

### Prerequisites

* Windows PowerShell 5.1 or greater, or
* [PowerShell Core](https://github.com/PowerShell/PowerShell)

### Installing FastPing via PowerShell Gallery

```powershell
Install-Module -Name 'FastPing' -Scope 'CurrentUser'
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

## Author

[Andrew Pearce](https://twitter.com/austoonz) - [https://andrewpearce.io](https://andrewpearce.io)

## Contributors

[Jake Morrison](https://twitter.com/JakeMorrison) - CI/CD standardization work
[Chris Dent](http://www.indented.co.uk/) - Network Calculation PowerShell code from the [Indented.Net.IP](https://www.powershellgallery.com/packages/Indented.Net.IP/) PowerShel Module. [Source code](https://github.com/indented-automation/Indented.Net.IP).