---
external help file: FastPing-help.xml
Module Name: FastPing
online version:
schema: 2.0.0
---

# Invoke-FastPing

## SYNOPSIS
Performs a series of asynchronous pings against a set of target hosts.

## SYNTAX

### Count (Default)
```
Invoke-FastPing [[-HostName] <String[]>] [-Count <Int32>] [-Timeout <Int32>] [-Interval <Int32>]
 [-EchoRequests <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Continuous
```
Invoke-FastPing [[-HostName] <String[]>] [-Continuous] [-Timeout <Int32>] [-Interval <Int32>]
 [-EchoRequests <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function uses the System.Net.Networkinformation.Ping object to perform a series of asynchronous pings against a set of target hosts.
Each ping result is calculated the specified number of echo requests.

## EXAMPLES

### EXAMPLE 1
```
Invoke-FastPing -HostName 'andrewpearce.io'
```

HostName         Online Status     p90   PercentLost
--------         ------ ------     ---   -----------
andrewpearce.io  True   Success    4     0

### EXAMPLE 2
```
Invoke-FastPing -HostName 'andrewpearce.io','doesnotexist.andrewpearce.io'
```

HostName         Online Status     p90   PercentLost
--------         ------ ------     ---   -----------
andrewpearce.io  True   Success    5     0
doesnotexist.an… False  Unknown          100

### EXAMPLE 3
```
Invoke-FastPing -HostName 'andrewpearce.io' -Count 5
```

This example generates five ping results against the host 'andrewpearce.io'.

### EXAMPLE 4
```
fp andrewpearce.io -n 5
```

This example pings the host 'andrewpearce.io' five times using syntax similar to ping.exe.

### EXAMPLE 5
```
Invoke-FastPing -HostName 'microsoft.com' -Timeout 500
```

This example pings the host 'microsoft.com' with a 500 millisecond timeout.

### EXAMPLE 6
```
fp microsoft.com -w 500
```

This example pings the host 'microsoft.com' with a 500 millisecond timeout using syntax similar to ping.exe.

### EXAMPLE 7
```
fp andrewpearce.io -Continuous
```

This example pings the host 'andrewpearce.io' continuously until CTRL+C is used.

### EXAMPLE 8
```
fp andrewpearce.io -t
```

This example pings the host 'andrewpearce.io' continuously until CTRL+C is used.

## PARAMETERS

### -HostName
String array of target hosts.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Computer, ComputerName, Host

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Count
Number of ping requests to send.
Aliased with 'n', like ping.exe.

```yaml
Type: Int32
Parameter Sets: Count
Aliases: N

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Continuous
Enables continuous pings against the target hosts.
Stop with CTRL+C.
Aliases with 't', like ping.exe.

```yaml
Type: SwitchParameter
Parameter Sets: Continuous
Aliases: T

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
Timeout in milliseconds to wait for each reply.
Defaults to 2 seconds (5000 ms).
Aliased with 'w', like ping.exe.

Per MSDN Documentation, "When specifying very small numbers for timeout, the Ping reply can be received even if timeout milliseconds have elapsed." (https://msdn.microsoft.com/en-us/library/ms144955.aspx).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: W

Required: False
Position: Named
Default value: 5000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interval
Number of milliseconds between ping requests.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -EchoRequests
Number of echo requests to use for each ping result.
Used to generate the calculated output fields.
Defaults to 4.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: RoundtripAveragePingCount

Required: False
Position: Named
Default value: 4
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
