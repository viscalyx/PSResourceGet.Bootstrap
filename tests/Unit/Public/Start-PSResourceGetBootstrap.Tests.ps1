[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'PSResourceGet.Bootstrap'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Start-PSResourceGetBootstrap' -Tag 'Public' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function Save-PSResource
            {
            }
        }

        Mock -CommandName Invoke-WebRequest
        Mock -CommandName Save-PSResource
        Mock -CommandName Expand-Archive
        Mock -CommandName Import-Module
        Mock -CommandName Rename-Item
        Mock -CommandName Remove-Item
    }

    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Scope'
            # cSpell: disable-next
            MockExpectedParameters = '[-Scope <string>] [-Version <string>] [-UseCompatibilityModule] [-CompatibilityModuleVersion <string>] [-ImportModule] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Destination'
            # cSpell: disable-next
            MockExpectedParameters = '-Destination <string> [-Version <string>] [-UseCompatibilityModule] [-CompatibilityModuleVersion <string>] [-ImportModule] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Start-PSResourceGetBootstrap').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When provided with valid parameters' {
        Context 'Weh using parameter set Scope' {
            It 'Should not throw any exceptions' {
                { Start-PSResourceGetBootstrap -Scope 'AllUsers' -Version '1.0.0' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Not -Throw
            }
        }

        Context 'Weh using parameter set Destination' {
            It 'Should not throw any exceptions' {
                { Start-PSResourceGetBootstrap -Destination $TestDrive -Version '1.0.0' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Not -Throw
            }
        }

        Context 'When provided with an valid version' {
            It 'Should not throw an exception' {
                { Start-PSResourceGetBootstrap -Destination $TestDrive -Version '1.0.0-preview' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Not -Throw
            }

            It 'Should not throw an exception for nuget version range' {
                { Start-PSResourceGetBootstrap -Destination $TestDrive -Version '[3.0.22,]' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Not -Throw
            }
        }
    }

    Context 'When provided with an invalid destination' {
        It 'Should throw an exception' {
            { Start-PSResourceGetBootstrap -Destination 'InvalidPath' -Version '1.0.0' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Throw
        }
    }

    Context 'When provided with an invalid scope' {
        It 'Should throw an exception' {
            { Start-PSResourceGetBootstrap -Scope 'InvalidScope' -Version '1.0.0' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Throw
        }
    }

    Context 'When provided with an invalid version' {
        It 'Should throw an exception' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Version '1.0.0-' -UseCompatibilityModule -CompatibilityModuleVersion '[3.0.22,]' -Force } | Should -Throw
        }
    }

    Context 'When provided with an invalid CompatibilityModuleVersion' {
        It 'Should throw an exception' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Version '1.0.0-' -UseCompatibilityModule -CompatibilityModuleVersion 'InvalidVersion' -Force } | Should -Throw
        }
    }

    Context 'When module is already loaded and its path matches the destination' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'PSResourceGet'
                    Path = $TestDrive
                }
            }
        }

        It 'Should not attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -UseCompatibilityModule -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -Times 0 -Exactly
        }
    }

    Context 'When module should be bootstrapped (module is not loaded or its path does not match the destination)' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context 'When module should be bootstrapped (module is not loaded or its path does not match the destination)' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context 'When parmeter Scope is used but the path Scope points to does not exist' {
        BeforeEach {
            Mock -CommandName Get-PSModulePath -MockWith {
                return "$TestDrive/MissingFolder"
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Scope 'CurrentUser' -UseCompatibilityModule -Force } | Should -Throw 'The path*does not exist for the scope*'

            Should -Invoke -CommandName Invoke-WebRequest -Times 0 -Exactly
        }
    }

    Context 'When module should be imported' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -UseCompatibilityModule -ImportModule -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
        }
    }

    Context 'When module fail to download' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }

            Mock -CommandName Invoke-WebRequest -MockWith {
                throw 'Mocked error'
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Force } | Should -Throw -ExpectedMessage 'Failed to download*'

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
            Should -Invoke -CommandName Rename-Item -Times 0 -Exactly
        }
    }

    Context 'When failing to rename the downloaded package to a zip file' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }

            Mock -CommandName Rename-Item -MockWith {
                throw 'Mocked error'
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Force } | Should -Throw -ExpectedMessage 'Failed to rename the downloaded package*'

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
            Should -Invoke -CommandName Rename-Item -Times 1 -Exactly
        }
    }

    Context 'When failing to expand the downloaded package' {
        BeforeEach {
            Mock -CommandName Get-Module -MockWith {
                return $null
            }

            Mock -CommandName Expand-Archive -MockWith {
                throw 'Mocked error'
            }
        }

        It 'Should attempt to download the module' {
            { Start-PSResourceGetBootstrap -Destination $TestDrive -Force } | Should -Throw -ExpectedMessage 'Failed to expand the (renamed) downloaded package*'

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
            Should -Invoke -CommandName Rename-Item -Times 1 -Exactly
        }
    }
}
