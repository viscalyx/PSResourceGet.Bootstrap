<#
    .SYNOPSIS
        Bootstraps the Microsoft.PowerShell.PSResourceGet module to the specified location.

    .DESCRIPTION
        The command Start-PSResourceGetBootstrap is used to bootstrap the Microsoft.PowerShell.PSResourceGet
        module.

        It supports two parameter sets: 'Destination' and 'Scope'. The 'Destination'
        parameter set allows you to specify a specific location to save the module,
        while the 'Scope' parameter set saves the module to the appropriate `$env:PSModulePath`
        location based on the specified scope ('CurrentUser' or 'AllUsers').

    .PARAMETER Destination
        Specifies the destination path where the module should be saved. This parameter
        is mandatory when using the 'Destination' parameter set. The path must be a valid
        container.

    .PARAMETER Scope
        Specifies the scope for saving the module. This parameter is used when using the
        'Scope' parameter set. The valid values are 'CurrentUser' and 'AllUsers'. The
        default value is 'CurrentUser'.

    .PARAMETER Version
        Specifies the version of the Microsoft.PowerShell.PSResourceGet module to download.
        If not specified, the latest version will be downloaded.

    .PARAMETER UseCompatibilityModule
        Indicates whether to use the compatibility module. If this switch parameter is
        present, the compatibility module will be downloaded.

    .PARAMETER CompatibilityModuleVersion
        Specifies the version of the compatibility module to download. If not specified,
        it will default to a minimum required range that includes previews.

    .PARAMETER Force
        Forces the operation without prompting for confirmation. This is useful when
        running the script in non-interactive mode.

    .OUTPUTS
        None.

    .EXAMPLE
        Start-PSResourceGetBootstrap -Destination 'C:\Modules'

        This example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving
        it to the specified destination path "C:\Modules".

    .EXAMPLE
        Start-PSResourceGetBootstrap -Scope 'AllUsers'

        This example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving
        it to the appropriate location based on the 'AllUsers' scope.

    .EXAMPLE
        Start-PSResourceGetBootstrap -UseCompatibilityModule

        This example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving
        it to the appropriate location based on the default scope ('CurrentUser').
        It will also save the compatibility module to the same location.
#>
function Start-PSResourceGetBootstrap
{
    # TODO: Change impact to 'Medium' when the script is stable.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'Scope')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Destination')]
        [ValidateScript({
            Test-Path -Path $_ -PathType 'Container'
        })]
        [System.String]
        $Destination,

        [Parameter(ParameterSetName = 'Scope')]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [System.String]
        $Scope = 'CurrentUser',

        [Parameter()]
        [ValidateScript({
            # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
            $_ -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$' -or
            # Need to support the Nuget range syntax as well.
            $_ -match '^[\[(][0-9\.\,]*[\])]$'
        })]
        [System.String]
        $Version,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseCompatibilityModule,

        [Parameter()]
        [ValidateScript({
            # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
            $_ -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$' -or
            # Need to support the Nuget range syntax as well.
            $_ -match '^[\[(][0-9\.\,]*[\])]$'
        })]
        [System.String]
        $CompatibilityModuleVersion = '[3.0.22,]',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ImportModule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    $name = 'Microsoft.PowerShell.PSResourceGet'

    switch ($PSCmdlet.ParameterSetName)
    {
        'Destination'
        {
            # Resolve relative path to absolute path.
            $Destination = Resolve-Path -Path $Destination -ErrorAction 'Stop'

            $verboseDescriptionMessage = $script:localizedData.Start_PSResourceGetBootstrap_Destination_ShouldProcessVerboseDescription -f $name, $Destination

            Write-Debug -Message ($script:localizedData.Start_PSResourceGetBootstrap_Destination_SaveModule -f $Destination)
        }

        'Scope'
        {
            $verboseDescriptionMessage = $script:localizedData.Start_PSResourceGetBootstrap_Scope_ShouldProcessVerboseDescription -f $name, $Scope

            $Destination = Get-PSModulePath -Scope $Scope

            Write-Debug -Message ($script:localizedData.Start_PSResourceGetBootstrap_Scope_SaveModule -f $Scope, $Destination)
        }
    }

    $loadedModule = Get-Module -Name $name

    if ($loadedModule -and $loadedModule.Path -match [System.Text.RegularExpressions.Regex]::Escape($Destination))
    {
        Write-Verbose -Message ($script:localizedData.Start_PSResourceGetBootstrap_AlreadyInUse -f $name)

        # Since it is loaded into the session, assume it is downloaded and working.
        $moduleAvailable = $true
    }
    else
    {
        $verboseWarningMessage = $script:localizedData.Start_PSResourceGetBootstrap_ShouldProcessVerboseWarning -f $name
        $captionMessage = $script:localizedData.Start_PSResourceGetBootstrap_ShouldProcessCaption -f $name

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            $moduleAvailable = $false

            try
            {
                if (-not $Version)
                {
                    # Default to latest version if no version is passed in parameter or specified in configuration.
                    $psResourceGetUri = "https://www.powershellgallery.com/api/v2/package/$name"
                }
                else
                {
                    $psResourceGetUri = "https://www.powershellgallery.com/api/v2/package/$name/$Version"
                }

                $invokeWebRequestParameters = @{
                    # TODO: Should support proxy parameters passed to the command.
                    Uri         = $psResourceGetUri
                    OutFile     = "$Destination/$name.nupkg" # cSpell: ignore nupkg
                    ErrorAction = 'Stop'
                }

                # $previousProgressPreference = $ProgressPreference
                # $ProgressPreference = 'SilentlyContinue'

                Invoke-WebRequest @invokeWebRequestParameters

                # $ProgressPreference = $previousProgressPreference

                $moduleAvailable = $true
            }
            catch
            {
                # cSpell: ignore SPSRGB
                $exception = New-Exception -ErrorRecord $_ -Message ($script:localizedData.Start_PSResourceGetBootstrap_FailedDownload -f $name)
                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SPSRGB0001' -ErrorCategory 'InvalidOperation' -TargetObject $name

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            if ($moduleAvailable)
            {
                try
                {
                    # On Windows PowerShell the command Expand-Archive do not like .nupkg as a zip archive extension.
                    $zipFileName = ((Split-Path -Path $invokeWebRequestParameters.OutFile -Leaf) -replace 'nupkg', 'zip')

                    $renameItemParameters = @{
                        Path    = $invokeWebRequestParameters.OutFile
                        NewName = $zipFileName
                        Force   = $true
                    }

                    Rename-Item @renameItemParameters
                }
                catch
                {
                    # If the rename fails, we should remove the .nupkg file.
                    Remove-Item -Path $invokeWebRequestParameters.OutFile

                    $exception = New-Exception -ErrorRecord $_ -Message ($script:localizedData.Start_PSResourceGetBootstrap_RenamedFailed -f $invokeWebRequestParameters.OutFile, $invokeWebRequestParameters.NewName)
                    $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SPSRGB0002' -ErrorCategory 'InvalidOperation' -TargetObject $invokeWebRequestParameters.OutFile

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }

                try
                {
                    $zipArchivePath = Join-Path -Path (Split-Path -Path $invokeWebRequestParameters.OutFile -Parent) -ChildPath $zipFileName

                    $expandArchiveParameters = @{
                        Path            = $zipArchivePath
                        DestinationPath = "$Destination/$name"
                        Force           = $true
                    }

                    Expand-Archive @expandArchiveParameters
                }
                catch
                {
                    $exception = New-Exception -ErrorRecord $_ -Message ($script:localizedData.Start_PSResourceGetBootstrap_ExpandFailed -f $zipArchivePath)
                    $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'SPSRGB0003' -ErrorCategory 'InvalidOperation' -TargetObject $zipArchivePath

                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
                finally
                {
                    # When the expand succeeds, we should remove the .zip file.
                    Remove-Item -Path $zipArchivePath
                }

                if ($ImportModule.IsPresent)
                {
                    Import-Module -Name $expandArchiveParameters.DestinationPath -Force
                }
            }
        }
        else
        {
            if ((Test-Path -Path (Join-Path -Path $Destination -ChildPath $name)))
            {
                # Since it is available in the destination, assume it is downloaded and can work.
                $moduleAvailable = $true

                Write-Debug -Message 'Did not bootstrap, but module is available in the destination.'
            }
        }
    }

    if ($moduleAvailable -and $UseCompatibilityModule.IsPresent)
    {
        $name = 'PowerShellGet'

        $loadedModule = Get-Module -Name $name

        if ($loadedModule -and $loadedModule.Path -match [System.Text.RegularExpressions.Regex]::Escape($Destination))
        {
            Write-Verbose -Message ($script:localizedData.Start_PSResourceGetBootstrap_AlreadyInUse -f $name)
        }
        else
        {
            $verboseDescriptionMessage = $script:localizedData.Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessVerboseDescription -f $name, $Destination
            $verboseWarningMessage = $script:localizedData.Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessVerboseWarning -f $name
            $captionMessage = $script:localizedData.Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessCaption -f $name

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                $savePowerShellGetParameters = @{
                    Name            = $name
                    Path            = $Destination
                    Repository      = 'PSGallery'
                    TrustRepository = $true

                    # If not specified, default to a minimum required range that includes previews.
                    Version = $CompatibilityModuleVersion
                    # TODO: Should probably be a switch parameter when there is a full release out.
                    Prerelease = $true
                }

                Save-PSResource @savePowerShellGetParameters

                if ($ImportModule.IsPresent)
                {
                    Import-Module -Name "$Destination/$name"
                }
            }
        }
    }
}
