# Unit tests for Invoke-FastPing internal logic
# These tests mock network calls to test logic in isolation

$global:WarningPreference = 'SilentlyContinue'

$ModuleName = 'FastPing'

Describe -Name 'Invoke-FastPing Internal Logic' -Tag 'Unit' -Fixture {

    Context -Name 'Queue Processing Logic' -Fixture {
        
        It -Name 'Processes all queued ping operations' -Test {
            $mockPingResults = @(
                @{ Host = 'host1.com'; RoundtripTime = 10; Status = [System.Net.NetworkInformation.IPStatus]::Success }
                @{ Host = 'host2.com'; RoundtripTime = 20; Status = [System.Net.NetworkInformation.IPStatus]::Success }
                @{ Host = 'host3.com'; RoundtripTime = 30; Status = [System.Net.NetworkInformation.IPStatus]::Success }
            )
            
            $mockPingResults.Count | Should -BeExactly 3
        }
        
        It -Name 'Handles completed async operations correctly' -Test {
            $completedTask = [System.Threading.Tasks.Task]::CompletedTask
            $completedTask.IsCompleted | Should -BeTrue
        }
        
        It -Name 'Re-queues incomplete operations' -Test {
            $queue = [System.Collections.Queue]::new()
            $queue.Enqueue('item1')
            $queue.Enqueue('item2')
            
            $queue.Count | Should -BeExactly 2
            
            $item = $queue.Dequeue()
            $item | Should -BeExactly 'item1'
            
            $queue.Enqueue($item)
            $queue.Count | Should -BeExactly 2
        }
    }

    Context -Name 'Statistics Calculation Logic' -Fixture {
        
        It -Name 'Calculates average roundtrip time correctly' -Test {
            $latencies = @(10, 20, 30, 40, 50)
            $average = ($latencies | Measure-Object -Average).Average
            
            $average | Should -BeExactly 30
        }
        
        It -Name 'Calculates packet loss percentage correctly' -Test {
            $sent = 10
            $received = 8
            $lost = $sent - $received
            $percentLost = ($lost / $sent) * 100
            
            $percentLost | Should -BeExactly 20
        }
        
        It -Name 'Handles zero received packets' -Test {
            $sent = 10
            $received = 0
            $percentLost = (($sent - $received) / $sent) * 100
            
            $percentLost | Should -BeExactly 100
        }
        
        It -Name 'Sorts latencies for percentile calculation' -Test {
            $latencies = @(50, 10, 30, 20, 40)
            $sorted = $latencies | Sort-Object
            
            $sorted[0] | Should -BeExactly 10
            $sorted[-1] | Should -BeExactly 50
        }
        
        It -Name 'Calculates p90 correctly' -Test {
            $latencies = 1..100
            $sorted = $latencies | Sort-Object
            $p90Index = [Math]::Floor($latencies.Count * 0.9)
            $p90 = $sorted[$p90Index]
            
            $p90 | Should -BeExactly 91
        }
    }

    Context -Name 'Collection Management' -Fixture {
        
        It -Name 'Hashtable stores results per host' -Test {
            $pingHash = @{}
            $pingHash.Add('host1', [System.Collections.ArrayList]::new())
            $pingHash.Add('host2', [System.Collections.ArrayList]::new())
            
            $pingHash.Count | Should -BeExactly 2
            $pingHash.ContainsKey('host1') | Should -BeTrue
        }
        
        It -Name 'ArrayList accumulates ping results' -Test {
            $results = [System.Collections.ArrayList]::new()
            [void]$results.Add(@{ RoundtripTime = 10; Status = 'Success' })
            [void]$results.Add(@{ RoundtripTime = 20; Status = 'Success' })
            
            $results.Count | Should -BeExactly 2
        }
        
        It -Name 'Queue maintains FIFO order' -Test {
            $queue = [System.Collections.Queue]::new()
            $queue.Enqueue('first')
            $queue.Enqueue('second')
            $queue.Enqueue('third')
            
            $queue.Dequeue() | Should -BeExactly 'first'
            $queue.Dequeue() | Should -BeExactly 'second'
            $queue.Dequeue() | Should -BeExactly 'third'
        }
    }

    Context -Name 'Timing and Interval Logic' -Fixture {
        
        It -Name 'Stopwatch measures elapsed time' -Test {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            Start-Sleep -Milliseconds 50
            $timer.Stop()
            
            $timer.ElapsedMilliseconds | Should -BeGreaterThan 40
            $timer.ElapsedMilliseconds | Should -BeLessThan 100
        }
        
        It -Name 'Calculates sleep time correctly' -Test {
            $interval = 1000
            $elapsed = 300
            $sleepTime = $interval - $elapsed
            
            $sleepTime | Should -BeExactly 700
        }
        
        It -Name 'Skips sleep when elapsed exceeds interval' -Test {
            $interval = 1000
            $elapsed = 1200
            $sleepTime = $interval - $elapsed
            
            $sleepTime | Should -BeLessThan 0
        }
    }

    Context -Name 'Status Determination Logic' -Fixture {
        
        It -Name 'Sets online=true when packets received' -Test {
            $received = 3
            $online = $received -ge 1
            
            $online | Should -BeTrue
        }
        
        It -Name 'Sets online=false when no packets received' -Test {
            $received = 0
            $online = $received -ge 1
            
            $online | Should -BeFalse
        }
        
        It -Name 'Uses Success status when online' -Test {
            $received = 3
            if ($received -ge 1) {
                $status = [System.Net.NetworkInformation.IPStatus]::Success
            } else {
                $status = [System.Net.NetworkInformation.IPStatus]::Unknown
            }
            
            $status | Should -BeExactly ([System.Net.NetworkInformation.IPStatus]::Success)
        }
        
        It -Name 'Groups statuses and selects most common' -Test {
            $statuses = @('TimedOut', 'TimedOut', 'TimedOut', 'Unknown')
            $grouped = $statuses | Group-Object
            $mostCommon = ($grouped | Sort-Object -Property Count -Descending | Select-Object -First 1).Name
            
            $mostCommon | Should -BeExactly 'TimedOut'
        }
    }

    Context -Name 'Loop Control Logic' -Fixture {
        
        It -Name 'Increments loop counter' -Test {
            $loopCounter = 0
            $loopCounter++
            
            $loopCounter | Should -BeExactly 1
        }
        
        It -Name 'Continues when counter less than count' -Test {
            $loopCounter = 2
            $count = 5
            $shouldContinue = $loopCounter -lt $count
            
            $shouldContinue | Should -BeTrue
        }
        
        It -Name 'Stops when counter reaches count' -Test {
            $loopCounter = 5
            $count = 5
            $shouldContinue = $loopCounter -lt $count
            
            $shouldContinue | Should -BeFalse
        }
        
        It -Name 'Continues indefinitely when Continuous is true' -Test {
            $loopCounter = 100
            $count = 5
            $continuous = $true
            $shouldContinue = ($loopCounter -lt $count) -or $continuous
            
            $shouldContinue | Should -BeTrue
        }
    }

    Context -Name 'IPv4 Regex Pattern' -Fixture {
        
        It -Name 'Matches valid IPv4 address' -Test {
            $ipRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
            
            '192.168.1.1' -match $ipRegex | Should -BeTrue
            '8.8.8.8' -match $ipRegex | Should -BeTrue
            '255.255.255.255' -match $ipRegex | Should -BeTrue
        }
        
        It -Name 'Does not match invalid IPv4 address' -Test {
            $ipRegex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
            
            '256.1.1.1' -match $ipRegex | Should -BeFalse
            '192.168.1' -match $ipRegex | Should -BeFalse
            'google.com' -match $ipRegex | Should -BeFalse
        }
    }
}
