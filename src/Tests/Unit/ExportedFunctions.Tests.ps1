Set-Location -Path $PSScriptRoot

$ModuleName = 'FastPing'

$PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")

if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force

Describe -Name $ModuleName -Fixture {

    $manifestContent = Test-ModuleManifest -Path $PathToManifest

    $manifestExported = ($manifestContent.ExportedFunctions).Keys
    $moduleExported = Get-Command -Module $ModuleName | Select-Object -ExpandProperty Name
    $exportedCommands = Get-Module -Name $ModuleName | Select-Object -ExpandProperty ExportedCommands

    Context -Name 'Exported Commands' -Fixture {

        Context -Name 'Number of commands' -Fixture {
            It -Name 'Exports the same number of public functions as what is listed in the Module Manifest' -Test {
                $manifestExported.Count | Should -BeExactly $moduleExported.Count
            }
        }

        Context -Name 'Exported commands' -Fixture {
            foreach ($command in $moduleExported)
            {
                It -Name "Includes the $command in the Module Manifest ExportedFunctions" -Test {
                    $manifestExported -contains $command | Should -BeTrue
                }
            }
        }

        Context -Name 'Exported aliases' -Fixture {
            foreach ($key in $manifestContent.ExportedAliases.GetEnumerator())
            {
                It -Name ('Exports the Alias {0}' -f $key.Key) -Test {
                    $exportedCommands.ContainsKey($key.Key) | Should -BeTrue
                }
            }
        }
    }

    Context -Name 'Command Help' -Fixture {
        foreach ($command in $moduleExported)
        {
            Context -Name $command -Fixture {
                $help = Get-Help -Name $command -Full

                It -Name 'Includes a Synopsis' -Test {
                    $help.Synopsis | Should -Not -BeNullOrEmpty
                }

                It -Name 'Includes a Description' -Test {
                    $help.description.Text | Should -Not -BeNullOrEmpty
                }

                It -Name 'Includes at least one example' -Test {
                    $help.examples.example.count | Should -BeGreaterOrEqual 1
                }
            }
        }
    }
}