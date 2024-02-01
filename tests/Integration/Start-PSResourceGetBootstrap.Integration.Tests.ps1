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

Describe 'Start-PSResourceGetBootstrap' {
    BeforeAll {
        $moduleName = 'Microsoft.PowerShell.PSResourceGet'
        $compatibilityModuleName = 'PowerShellGet'
    }

    Context 'When using Scope parameter set' {
        It 'Should bootstrap the module to the specified scope' {
            { Start-PSResourceGetBootstrap -Scope 'AllUsers' -Force -Verbose } | Should -Not -Throw

            $allUsersPath = Get-PSModulePath -Scope 'AllUsers'

            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($allUsersPath)
            } | Should -Not -BeNullOrEmpty
        }

        It 'Should bootstrap the module and compatibility to the specified scope' {
            $currentUserPath = Get-PSModulePath -Scope 'CurrentUser'

            # Must create the path first, otherwise the test will fail if it does not exist.
            New-Item -Path $currentUserPath -ItemType 'Directory' -Force | Out-Null

            { Start-PSResourceGetBootstrap -Scope 'CurrentUser' -UseCompatibilityModule -Force -Verbose } | Should -Not -Throw

            Get-Module $moduleName -ListAvailable | Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($currentUserPath)
            } | Should -Not -BeNullOrEmpty

            Get-Module $compatibilityModuleName -ListAvailable | Where-Object -FilterScript {
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
            { Start-PSResourceGetBootstrap -Destination $testFolder1 -Force -Verbose } | Should -Not -Throw

            Test-Path -Path "$testFolder1/$moduleName" | Should -BeTrue
        }

        It 'Should bootstrap the module and compatibility to the specified scope' {
            { Start-PSResourceGetBootstrap -Destination $testFolder2 -UseCompatibilityModule -Force -Verbose } | Should -Not -Throw

            Test-Path -Path "$testFolder2/$moduleName" | Should -BeTrue
            Test-Path -Path "$testFolder2/$compatibilityModuleName" | Should -BeTrue
        }
    }
}
