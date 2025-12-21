# Performance Benchmarks - These make REAL network calls
# Run manually before/after optimization to measure improvements
# NOT part of automated CI/CD pipeline

$global:WarningPreference = 'SilentlyContinue'
Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

Describe -Name 'Invoke-FastPing Performance Benchmarks' -Tag 'Performance', 'Integration' -Fixture {

    BeforeAll {
        Write-Host ''
        Write-Host '⚠️  WARNING: These tests make REAL network calls' -ForegroundColor Yellow
        Write-Host '   They are slow and require internet connectivity' -ForegroundColor Yellow
        Write-Host '   Run manually with: Invoke-Pester -Tag Performance' -ForegroundColor Yellow
        Write-Host ''
    }

    Context -Name 'Baseline Performance Metrics' -Fixture {
        
        It -Name 'Single host completes within reasonable time' -Test {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-FastPing -HostName '1.1.1.1' -Timeout 1000 -EchoRequests 4
            $timer.Stop()
            
            $result | Should -Not -BeNullOrEmpty
            $timer.ElapsedMilliseconds | Should -BeLessThan 2000
            
            Write-Host "Single host: $($timer.ElapsedMilliseconds)ms"
        }

        It -Name '10 hosts complete within reasonable time' -Test {
            $hosts = 1..10 | ForEach-Object { "8.8.8.$_" }
            
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 4
            $timer.Stop()
            
            $results.Count | Should -BeExactly 10
            $timer.ElapsedMilliseconds | Should -BeLessThan 3000
            
            Write-Host "10 hosts: $($timer.ElapsedMilliseconds)ms"
        }

        It -Name '50 hosts complete within reasonable time' -Test {
            $hosts = @(
                (1..25 | ForEach-Object { "8.8.8.$_" })
                (1..25 | ForEach-Object { "1.1.1.$_" })
            )
            
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 4
            $timer.Stop()
            
            $results.Count | Should -BeExactly 50
            $timer.ElapsedMilliseconds | Should -BeLessThan 5000
            
            Write-Host "50 hosts: $($timer.ElapsedMilliseconds)ms"
        }

        It -Name '100 hosts complete within reasonable time' -Test {
            $hosts = @(
                (1..50 | ForEach-Object { "8.8.8.$_" })
                (1..50 | ForEach-Object { "1.1.1.$_" })
            )
            
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 4
            $timer.Stop()
            
            $results.Count | Should -BeExactly 100
            $timer.ElapsedMilliseconds | Should -BeLessThan 7000
            
            Write-Host "100 hosts: $($timer.ElapsedMilliseconds)ms"
        }
    }

    Context -Name 'Memory Usage Benchmarks' -Fixture {
        
        It -Name 'Memory usage stays reasonable for 100 hosts' -Test {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $beforeMemory = [System.GC]::GetTotalMemory($false)
            
            $hosts = 1..100 | ForEach-Object { "192.168.1.$_" }
            $results = Invoke-FastPing -HostName $hosts -Timeout 500 -EchoRequests 4
            
            $afterMemory = [System.GC]::GetTotalMemory($false)
            $memoryUsedMB = ($afterMemory - $beforeMemory) / 1MB
            
            $results.Count | Should -BeExactly 100
            $memoryUsedMB | Should -BeLessThan 50
            
            Write-Host "Memory used for 100 hosts: $([Math]::Round($memoryUsedMB, 2))MB"
        }
    }

    Context -Name 'Repeated Execution Performance' -Fixture {
        
        It -Name 'Multiple iterations maintain consistent performance' -Test {
            $hosts = 1..10 | ForEach-Object { "8.8.8.$_" }
            $iterations = 5
            $timings = @()
            
            for ($i = 0; $i -lt $iterations; $i++) {
                $timer = [System.Diagnostics.Stopwatch]::StartNew()
                $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 4
                $timer.Stop()
                
                $timings += $timer.ElapsedMilliseconds
                $results.Count | Should -BeExactly 10
            }
            
            $avgTime = ($timings | Measure-Object -Average).Average
            $maxTime = ($timings | Measure-Object -Maximum).Maximum
            $minTime = ($timings | Measure-Object -Minimum).Minimum
            
            $variance = $maxTime - $minTime
            $variance | Should -BeLessThan 1000
            
            Write-Host "Repeated execution - Avg: $([Math]::Round($avgTime, 0))ms, Min: $minTime ms, Max: $maxTime ms, Variance: $variance ms"
        }
    }

    Context -Name 'Concurrent Execution Stress Test' -Fixture {
        
        It -Name 'Handles high echo request count efficiently' -Test {
            $hosts = 1..10 | ForEach-Object { "8.8.8.$_" }
            
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 20
            $timer.Stop()
            
            $results.Count | Should -BeExactly 10
            $results[0].Sent | Should -BeExactly 20
            $timer.ElapsedMilliseconds | Should -BeLessThan 5000
            
            Write-Host "10 hosts x 20 echo requests: $($timer.ElapsedMilliseconds)ms"
        }
    }

    Context -Name 'CPU Efficiency Benchmarks' -Fixture {
        
        It -Name 'CPU time is minimal compared to wall clock time' -Test {
            $hosts = 1..20 | ForEach-Object { "8.8.8.$_" }
            
            $process = [System.Diagnostics.Process]::GetCurrentProcess()
            $startCpuTime = $process.TotalProcessorTime
            
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-FastPing -HostName $hosts -Timeout 1000 -EchoRequests 4
            $timer.Stop()
            
            $process.Refresh()
            $endCpuTime = $process.TotalProcessorTime
            $cpuTimeMs = ($endCpuTime - $startCpuTime).TotalMilliseconds
            
            $results.Count | Should -BeExactly 20
            
            $cpuPercentage = ($cpuTimeMs / $timer.ElapsedMilliseconds) * 100
            $cpuPercentage | Should -BeLessThan 50
            
            Write-Host "CPU time: $([Math]::Round($cpuTimeMs, 0))ms / Wall time: $($timer.ElapsedMilliseconds)ms = $([Math]::Round($cpuPercentage, 1))% CPU"
        }
    }
}
