# Changelog

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
