<#
    .SYNOPSIS
        Unit test for BootstrapPSResourceGet DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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

Describe 'BootstrapPSResourceGet' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [BootstrapPSResourceGet]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [BootstrapPSResourceGet]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [BootstrapPSResourceGet]::new()
                $instance.GetType().Name | Should -Be 'BootstrapPSResourceGet'
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    ModuleScope      = 'CurrentUser'
                }

                <#
                    This mocks the method GetCurrentState() and AssertProperties().

                    Method Get() will call the base method Get() which will
                    call back to the derived class method GetCurrentState()
                    to get the result to return from the derived method Get().
                #>
                $script:mockBootstrapPSResourceGetInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                        return [System.Collections.Hashtable] @{
                            IsSingleInstance = 'Yes'
                            ModuleScope      = 'CurrentUser'
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockBootstrapPSResourceGetInstance.Get()

                $currentState.IsSingleInstance | Should -Be 'Yes'
                $currentState.ModuleScope | Should -Be 'CurrentUser'
                $currentState.Destination | Should -BeNullOrEmpty
                $currentState.Version | Should -BeNullOrEmpty
                $currentState.Reasons | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    ModuleScope      = 'CurrentUser'
                }

                <#
                    This mocks the method GetCurrentState() and AssertProperties().

                    Method Get() will call the base method Get() which will
                    call back to the derived class method GetCurrentState()
                    to get the result to return from the derived method Get().
                #>
                $script:mockBootstrapPSResourceGetInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                        return [System.Collections.Hashtable] @{
                            IsSingleInstance = 'Yes'
                            ModuleScope      = $null
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockBootstrapPSResourceGetInstance.Get()

                $currentState.IsSingleInstance | Should -Be 'Yes'
                $currentState.ModuleScope | Should -BeNullOrEmpty
                $currentState.Destination | Should -BeNullOrEmpty
                $currentState.Version | Should -BeNullOrEmpty

                $currentState.Reasons | Should -HaveCount 1
                $currentState.Reasons.Code | Should -Be 'BootstrapPSResourceGet:BootstrapPSResourceGet:ModuleScope'

                # The output is different between Windows PowerShell and PowerShell.
                if ($IsCoreCLR)
                {
                    $currentState.Reasons.Phrase | Should -Be 'The property ModuleScope should be "CurrentUser", but was null'
                }
                else
                {
                    $currentState.Reasons.Phrase | Should -Be 'The property ModuleScope should be "CurrentUser", but was ""'
                }
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                IsSingleInstance = 'Yes'
                ModuleScope      = 'CurrentUser'
            } |
                # Mock method Modify which is called by the base method Set().
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                    $script:mockMethodModifyCallCount += 1
                } -PassThru
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockMethodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance |
                    <#
                        Mock parent method Compare() and child method AssertProperties()
                        which is called by the base method Set()
                    #>
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'ModuleScope'
                            ExpectedValue = 'CurrentUser'
                            ActualValue   = $null
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                IsSingleInstance = 'Yes'
                ModuleScope      = 'CurrentUser'
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'ModuleScope'
                            ExpectedValue = 'CurrentUser'
                            ActualValue   = $null
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When specifying the value CurrentScope for parameter ModuleScope' {
        Context 'When PSResourceGet is missing' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When PSResourceGet exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.ModuleScope | Should -Be 'CurrentUser'
                }
            }
        }
    }

    Context 'When specifying the value AllUsers for parameter ModuleScope' {
        Context 'When PSResourceGet is missing' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'AllUsers'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When PSResourceGet exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'AllUsers'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.ModuleScope | Should -Be ('AllUsers')
                }
            }
        }
    }

    Context 'When specifying a path for parameter Destination' {
        Context 'When PSResourceGet is missing' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -BeNullOrEmpty
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When PSResourceGet exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -Be $TestDrive
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When specifying both parameters Destination and Version' {
        Context 'When PSResourceGet is missing or have wrong version' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                        Version          = '1.0.0'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -BeNullOrEmpty
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                    $currentState.Version | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When PSResourceGet exist with the correct version' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                        Version          = '1.0.0'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -Be $TestDrive
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                    $currentState.Version | Should -Be '1.0.0'
                }
            }
        }
    }

    Context 'When specifying both parameters ModuleScope and Version' {
        Context 'When PSResourceGet is missing or have wrong version' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                        Version          = '1.0.0'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -BeNullOrEmpty
                    $currentState.ModuleScope | Should -BeNullOrEmpty
                    $currentState.Version | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When PSResourceGet exist with the correct version' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                        Version          = '1.0.0'
                    }
                }

                Mock -CommandName Test-ModuleExist -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockBootstrapPSResourceGetInstance.GetCurrentState(
                        @{
                            IsSingleInstance = 'Yes'
                        }
                    )

                    $currentState.IsSingleInstance | Should -Be 'Yes'
                    $currentState.Destination | Should -BeNullOrEmpty
                    $currentState.ModuleScope | Should -Be 'CurrentUser'
                    $currentState.Version | Should -Be '1.0.0'
                }
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\Modify()' -Tag 'Modify' {
    Context 'When specifying parameter ModuleScope' {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                    } | Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru
                }

                Mock -CommandName Start-PSResourceGetBootstrap
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            ModuleScope = 'CurrentUser'
                        }
                    )

                    Should -Invoke -CommandName Start-PSResourceGetBootstrap -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When specifying both parameters ModuleScope and Version' {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope      = 'CurrentUser'
                        Version          = '1.0.0'
                    } | Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru
                }

                Mock -CommandName Start-PSResourceGetBootstrap
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            ModuleScope = 'CurrentUser'
                            Version     = '1.0.0'
                        }
                    )

                    Should -Invoke -CommandName Start-PSResourceGetBootstrap -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When specifying parameter Destination' {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                    } | Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru
                }

                Mock -CommandName Start-PSResourceGetBootstrap
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Destination = $TestDrive
                        }
                    )

                    Should -Invoke -CommandName Start-PSResourceGetBootstrap -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When specifying both parameters ModuleScope and Version' {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        Destination      = $TestDrive
                        Version          = '1.0.0'
                    } | Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru
                }

                Mock -CommandName Start-PSResourceGetBootstrap
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Destination = $TestDrive
                            Version     = '1.0.0'
                        }
                    )

                    Should -Invoke -CommandName Start-PSResourceGetBootstrap -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'BootstrapPSResourceGet\AssertProperties()' -Tag 'AssertProperties' {
    <#
        These tests just check for the string localized ID. Since the error is part
        of a command outside of PSResourceGet.Bootstrap a small change to the
        localized string should not fail these tests.
    #>
    Context 'When passing mutually exclusive parameters' {
        Context 'When passing ModuleScope and Destination' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                        IsSingleInstance = 'Yes'
                        ModuleScope = 'CurrentUser'
                        Destination = $TestDrive
                    }
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $mockBootstrapPSResourceGetInstance.AssertProperties(
                            @{
                                ModuleScope = 'CurrentUser'
                                Destination = $TestDrive
                            }
                        )
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }
    }

    Context 'When passing parameter ModuleScope and the scope''s path does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    ModuleScope      = 'CurrentUser'
                }
            }

            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ScopePathInvalid -f 'CurrentUser', (Get-PSModulePath -Scope 'CurrentUser')

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ScopePathInvalid -f 'CurrentUser', (Get-PSModulePath -Scope 'CurrentUser')

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ScopePathInvalid -f 'CurrentUser', (Get-PSModulePath -Scope 'CurrentUser')

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When passing parameter Destination and the path does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    Destination      = $TestDrive
                }
            }

            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.DestinationInvalid -f $TestDrive

                $mockErrorMessage += "*Parameter*Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.DestinationInvalid -f $TestDrive

                $mockErrorMessage += "*Parameter*Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.DestinationInvalid -f $TestDrive

                $mockErrorMessage += "*Parameter*Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When passing parameter Version and the version is not valid' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    Destination      = $TestDrive
                    Version          = '1.0.0:-WrongTag'
                }
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.VersionInvalid -f '1.0.0:-WrongTag'

                $mockErrorMessage += "*Parameter*Version*"

                { $script:mockBootstrapPSResourceGetInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.VersionInvalid -f '1.0.0:-WrongTag'

                $mockErrorMessage += "*Parameter*Version*"

                { $script:mockBootstrapPSResourceGetInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.VersionInvalid -f '1.0.0:-WrongTag'

                $mockErrorMessage += "*Parameter*Version*"

                { $script:mockBootstrapPSResourceGetInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When neither of the parameters ModuleScope or Destination are specified' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                }
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.MissingRequiredParameter

                $mockErrorMessage += "*Parameter*ModuleScope, Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.MissingRequiredParameter

                $mockErrorMessage += "*Parameter*ModuleScope, Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.MissingRequiredParameter

                $mockErrorMessage += "*Parameter*ModuleScope, Destination*"

                { $script:mockBootstrapPSResourceGetInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When an invalid value is passed in ModuleScope' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockBootstrapPSResourceGetInstance = [BootstrapPSResourceGet] @{
                    IsSingleInstance = 'Yes'
                    ModuleScope      = 'InvalidScope'
                }
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ModuleScopeInvalid -f 'InvalidScope'

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ModuleScopeInvalid -f 'InvalidScope'

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockBootstrapPSResourceGetInstance.localizedData.ModuleScopeInvalid -f 'InvalidScope'

                $mockErrorMessage += "*Parameter*ModuleScope*"

                { $script:mockBootstrapPSResourceGetInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
