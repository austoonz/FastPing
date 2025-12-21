# Changelog

## v0.7.0 - 2025-12-21

### Changed
- **Invoke-FastPing performance significantly improved** through internal refactoring
- DNS resolution now cached across ping iterations for faster repeated hostname lookups
- Memory usage optimized with better resource management and disposal

### Added
- Comprehensive performance benchmark test suite for measuring ping operation speed
- Enhanced unit test coverage with logic isolation tests using mocked network calls
- Improved test organization separating unit, integration, and performance test categories

### Technical Details
- Replaced internal queue implementation with pre-allocated collections for better performance
- Implemented `Task.WaitAll()` for improved async coordination instead of polling
- Added proper disposal patterns to prevent memory leaks during ping operations

## v0.6.0 - 2022-04-18

- Invoke-FastPing updated with additional output properties
- The parameter `RoundtripAveragePingCount` has been renamed to `EchoRequests` with the original name added as an alias.

## v0.5.2 - 2021-01-03

- Invoke-PingSweep will not sort output based on the IP Address

## v0.5.1 - 2019-05-11

- Fixed positional parameter for Invoke-PingSweep

## v0.5.0 - 2019-05

- Added private functions from the
[Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)
module by Chris Dent to allow for network range calculations without
taking a dependency.
- Added the `Invoke-PingSweep` function.

## v0.4.2 - 2019-04-27

- Rebuild to update file date stamps

## v0.4.1 - 2019-04-27

### Invoke-FastPing Updates
- Added Help for `-Continuous` Parameter

### Manifest Updates
- Updated CompatiblePSEditions
- Added PrivateData Tags to indicate platform compatibility

## v0.4.0 - 2019-04-20

### Invoke-FastPing Updates
- Added `-Continuous` Parameter
- Added ParameterSet options for `-Count` or `-Continuous`

### Invoke-Build Updates
- Updated Desktop edition to support either AWSPowerShell or AWSPowerShell.NetCore
- Bumped required module versions for InvokeBuild, Pester, PlatyPS and PSScriptAnalyzer

## v0.3.0 - 2019-03-09

### Invoke-FastPing Updates
- Added `-Interval` Parameter
- Fixed RoundTripAverage for responses <1 millisecond

## v0.2.0 - 2019-03-04

### Invoke-FastPing Updates
- Added `-Count` Parameter
- Added `-Timeout` Parameter

## v0.1.0 - 2019-03-01

### Initial Release
- Added `Invoke-FastPing` Function
