---
external help file: FastPing-help.xml
Module Name: FastPing
online version:
schema: 2.0.0
---

# Invoke-PingSweep

## SYNOPSIS
Performs a ping sweep against a series of target IP Addresses.

## SYNTAX

### FromStartAndEnd (Default)
```
Invoke-PingSweep [-StartIP] <String> [-EndIP] <String> [-ReturnOnlineOnly] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FromIPAndMask
```
Invoke-PingSweep [-IPAddress] <String> [-SubnetMask] <String> [-ReturnOnlineOnly]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function calculates the list of IP Addresses to target, and wraps
a call to Invoke-FastPingto perform the ping sweep.

## EXAMPLES

### EXAMPLE 1
```
Invoke-PingSweep -StartIP '1.1.1.1' -EndIP '1.1.1.5'
```

HostName RoundtripAverage Online  Status
-------- ---------------- ------  ------
1.1.1.3                19   True Success
1.1.1.4                22   True Success
1.1.1.1                21   True Success
1.1.1.2                19   True Success
1.1.1.5                24   True Success

### EXAMPLE 2
```
Invoke-PingSweep -IPAddress '1.1.1.1' -SubnetMask '255.255.255.252'
```

HostName RoundtripAverage Online  Status
-------- ---------------- ------  ------
1.1.1.2                21   True Success
1.1.1.1                16   True Success

## PARAMETERS

### -StartIP
The IP Address to start from.

```yaml
Type: String
Parameter Sets: FromStartAndEnd
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndIP
The IP Address to finish with.

```yaml
Type: String
Parameter Sets: FromStartAndEnd
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPAddress
An IP Address, to be matched with an appropriate Subnet Mask.

```yaml
Type: String
Parameter Sets: FromIPAndMask
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubnetMask
A Subnet Mask for network range calculations.

```yaml
Type: String
Parameter Sets: FromIPAndMask
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnOnlineOnly
{{ Fill ReturnOnlineOnly Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
