[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Bootstrap Script' -Tag 'BootstrapScript' {
    BeforeAll {
        $moduleName = 'Microsoft.PowerShell.PSResourceGet'
        $compatibilityModuleName = 'PowerShellGet'

        # Get the paths before removing the module DscResource.Common.
        $allUsersPath = Get-PSModulePath -Scope 'AllUsers'
        $currentUserPath = Get-PSModulePath -Scope 'CurrentUser'
    }

    Context 'Pre-test cleanup' {
        It 'Should not have PSResourceGet.Bootstrap module imported in session' {
            Get-Module -Name 'PSResourceGet.Bootstrap' -All | Remove-Module -Force -ErrorAction 'SilentlyContinue'
            Get-Module -Name 'PSResourceGet.Bootstrap' -All | Should -BeNullOrEmpty
        }

        It 'Should not have DscResource.Common module available' {
            # Remove the module from the session to ensure that the module is not available.
            Get-Module -Name 'DscResource.Common' -All |
                Remove-Module -Force -ErrorAction 'SilentlyContinue'

            # Remove the module folder to ensure that the module is not available.
            Remove-Item -Path './output/RequiredModules/DscResource.Common' -Recurse -Force

            Get-Module -Name 'DscResource.Common' -ListAvailable | Should -BeNullOrEmpty -Because 'If the module is available there could be false positive tests.'
        }
    }

    Context 'When using Scope parameter set' {
        It 'Should bootstrap the module to the specified scope AllUsers' {
            {
                if ($IsLinux)
                {
                    # TODO: This works but does not output the verbose messages.
                    sudo pwsh -Command "& $PwD/output/bootstrap.ps1 -Scope 'AllUsers' -Force -Verbose"
                }
                else
                {
                    & ./output/bootstrap.ps1 -Scope 'AllUsers' -Force -Verbose
                }
            } | Should -Not -Throw

            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($allUsersPath)
            } | Should -Not -BeNullOrEmpty
        }

        It 'Should bootstrap the module and compatibility to the specified scope CurrentUser' {
            # Must create the path first, otherwise the test will fail if it does not exist.
            New-Item -Path $currentUserPath -ItemType 'Directory' -Force | Out-Null

            { & ./output/bootstrap.ps1 -Scope 'CurrentUser' -UseCompatibilityModule -Force -Verbose } | Should -Not -Throw

            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($currentUserPath)
            } | Should -Not -BeNullOrEmpty

            Get-Module $compatibilityModuleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($currentUserPath)
            } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using Invoke-Expression to initiate the bootstrap script (with defaults)' {
        BeforeAll {
            Remove-Item -Path "$currentUserPath/$moduleName" -Recurse -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should have removed the downloaded module in previous tests' {
            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($currentUserPath)
            } | Should -BeNullOrEmpty
        }

        It 'Should bootstrap the module to the default scope CurrentUser' {
            # Must create the path first, otherwise the test will fail if it does not exist.
            New-Item -Path $currentUserPath -ItemType 'Directory' -Force | Out-Null

            $script = Get-Content -Path './output/bootstrap.ps1' -Raw

            # Set default parameters for the command that the script runs.
            $PSDefaultParameterValues['Start-PSResourceGetBootstrap:Force'] = $true
            $PSDefaultParameterValues['Start-PSResourceGetBootstrap:Verbose'] = $true

            { $script | Invoke-Expression } | Should -Not -Throw

            $PSDefaultParameterValues.Remove('Start-PSResourceGetBootstrap:Force')
            $PSDefaultParameterValues.Remove('Start-PSResourceGetBootstrap:Verbose')

            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($currentUserPath)
            } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using Destination parameter set' {
        BeforeAll {
            $testFolder1 = "$TestDrive/Test1"
            $testFolder2 = "$TestDrive/Test2"

            New-Item -Path $testFolder1 -ItemType 'Directory' -Force | Out-Null
            New-Item -Path $testFolder2 -ItemType 'Directory' -Force | Out-Null
        }

        It 'Should bootstrap the module to the specified scope' {
            { & ./output/bootstrap.ps1 -Destination $testFolder1 -Force -Verbose } | Should -Not -Throw

            Test-Path -Path "$testFolder1/$moduleName" | Should -BeTrue
        }

        It 'Should bootstrap the module and compatibility to the specified scope' {
            { & ./output/bootstrap.ps1 -Destination $testFolder2 -UseCompatibilityModule -Force -Verbose } | Should -Not -Throw

            Test-Path -Path "$testFolder2/$moduleName" | Should -BeTrue
            Test-Path -Path "$testFolder2/$compatibilityModuleName" | Should -BeTrue
        }
    }
}
