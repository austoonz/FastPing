Describe -Name 'Module Manifest' -Fixture {
    BeforeAll {
        $module = Get-Module -Name 'FastPing'
        if (-not $module) {
            throw 'FastPing module is not loaded. This should not happen in test context.'
        }
        $script:ModuleName = 'FastPing'
        $script:ModuleManifestFilePath = [System.IO.Path]::Combine($module.ModuleBase, "$script:ModuleName.psd1")
        $script:Manifest = Test-ModuleManifest -Path $script:ModuleManifestFilePath
    }

    It -Name 'Has the correct root module' -Test {
        ($script:Manifest).RootModule | Should -BeExactly "$script:ModuleName.psm1"
    }

    It -Name 'Has a valid version' -Test {
        $assertion = ($script:Manifest).Version
        $assertion.ToString().Split('.') | Should -HaveCount 3
    }

    It -Name 'Is compatible with PSEdition: <_>' -TestCases @(
        'Core'
        'Desktop'
    ) -Test {
        ($script:Manifest).CompatiblePSEditions | Should -Contain $_
    }

    It -Name 'Requires PowerShell version 5.1' -Test {
        $assertion = ($script:Manifest).PowerShellVersion
        $expected = [System.Version]'5.1'
        $assertion | Should -BeExactly $expected
    }

    Context -Name 'Exported Functions' -Fixture {
        It -Name 'Exports the correct number of functions' -Test {
            $assertion = Get-Command -Module $script:ModuleName -CommandType Function
            $assertion | Should -HaveCount 2
        }

        It -Name '<_>' -TestCases @(
            'Invoke-FastPing'
            'Invoke-PingSweep'
        ) -Test {
            { Get-Command -Name $_ -Module $script:ModuleName -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context -Name 'Exported Aliases' -Fixture {
        It -Name 'Exports five aliases' -Test {
            ($script:Manifest).ExportedAliases.GetEnumerator() | Should -HaveCount 5
        }

        It -Name '<Alias>' -TestCases @(
            @{ Alias = 'fp' }
            @{ Alias = 'fping' }
            @{ Alias = 'FastPing' }
            @{ Alias = 'PingSweep' }
            @{ Alias = 'psweep' }
        ) -Test {
            $assertion = Get-Alias -Name $Alias -ErrorAction SilentlyContinue
            $assertion | Should -Not -BeNullOrEmpty
            $assertion.Source | Should -BeExactly $script:ModuleName
        }
    }
}