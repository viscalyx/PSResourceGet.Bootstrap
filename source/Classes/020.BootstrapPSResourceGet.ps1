<#
    .SYNOPSIS
        The `BootstrapPSResourceGet` DSC resource is used to bootstrap the module
        Microsoft.PowerShell.PSResourceGet to the specified location.

    .DESCRIPTION
        The `BootstrapPSResourceGet` DSC resource is used to bootstrap the module
        Microsoft.PowerShell.PSResourceGet to the specified location.

        It supports two parameter sets: 'Destination' and 'Scope'. The 'Destination'
        parameter set allows you to specify a specific location to save the module,
        while the 'Scope' parameter set saves the module to the appropriate `$env:PSModulePath`
        location based on the specified scope ('CurrentUser' or 'AllUsers').

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user.

        ## Requirements

        * Target machine must be running a operating system supporting running
          class-based DSC resources.
        * Target machine must support running Microsoft.PowerShell.PSResourceGet.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/viscalyx/PSResourceGet.Bootstrap/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+BootstrapPSResourceGet).

        ### Property **Reasons** does not work with **PSDscRunAsCredential**

        When using the built-in parameter **PSDscRunAsCredential** the read-only
        property **Reasons** will return empty values for the properties **Code**
        and **Phrase. The built-in property **PSDscRunAsCredential** does not work
        together with class-based resources that using advanced type like the parameter
        **Reasons** have.

    .PARAMETER Destination
        Specifies the destination path where the module should be saved. This parameter
        is mandatory when using the 'Destination' parameter set. The path must be a valid
        container. This parameter may not be used at the same time as the parameter Scope.

    .PARAMETER Scope
        Specifies the scope for saving the module. This parameter is used when using the
        'Scope' parameter set. The valid values are 'CurrentUser' and 'AllUsers'. The
        default value is 'CurrentUser'. This parameter may not be used at the same time
        as the parameter Destination.

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

    .PARAMETER ImportModule
        Indicates whether to import the module after it has been downloaded.

    .PARAMETER Ensure
        Specifies if the server audit should be present or absent. If set to `Present`
        the audit will be added if it does not exist, or updated if the audit exist.
        If `Absent` then the audit will be removed from the server. Defaults to
        `Present`.

    .EXAMPLE
        Invoke-DscResource -ModuleName PSResourceGet.Bootstrap -Name BootstrapPSResourceGet -Method Get -Property @{
            IsSingleInstance = 'Yes'
            Scope            = 'CurrentUser'
        }

        This example shows how to call the resource using Invoke-DscResource. This
        example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving
        it to the appropriate location based on the default scope ('CurrentUser').
        It will also save the compatibility module to the same location.
#>
[DscResource(RunAsCredential = 'Optional')]
class BootstrapPSResourceGet : ResourceBase
{
    [DscProperty(Key)]
    [ValidateSet('Yes')]
    [System.String]
    $IsSingleInstance

    # The Destination is evaluated if exist in AssertProperties().
    [DscProperty()]
    [System.String]
    $Destination

    # The Scope is evaluated if exist in AssertProperties().
    [DscProperty()]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [System.String]
    $Scope

    # The Version is evaluated if exist in AssertProperties().
    [DscProperty()]
    [System.String]
    $Version

    # [DscProperty()]
    # [Nullable[System.Boolean]]
    # $UseCompatibilityModule

    # # The CompatibilityModuleVersion is evaluated if exist in AssertProperties().
    # [DscProperty()]
    # [System.String]
    # $CompatibilityModuleVersion

    # [DscProperty()]
    # [Nullable[System.Boolean]]
    # $ImportModule

    # [DscProperty()]
    # [Ensure]
    # $Ensure = [Ensure]::Present

    BootstrapPSResourceGet () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'IsSingleInstance'
        )
    }

    [BootstrapPSResourceGet] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter keyProperty will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $keyProperty)
    {
        Write-Verbose -Message $this.localizedData.EvaluateModule

        $currentState = @{}

        # Need to find out how to evaluate state since there are no key properties for that.
        $assignedDscProperties = $this | Get-DscProperty -HasValue -Attribute @(
            'Mandatory'
            'Optional'
        )

        $testModuleExistParameters = @{
            Name = 'Microsoft.PowerShell.PSResourceGet'
        }

        if ($assignedDscProperties.Keys -contains 'Version')
        {
            $testModuleExistParameters.Version = $assignedDscProperties.Version

            $currentState.Version = ''
        }

        # If it is scope wasn't specified, then destination was specified.
        if ($assignedDscProperties.Keys -contains 'Scope')
        {
            Write-Verbose -Message (
                $this.localizedData.EvaluatingScope -f $assignedDscProperties.Scope
            )

            $currentState.Scope = ''

            $testModuleExistParameters.Scope = $assignedDscProperties.Scope

            if ((Test-ModuleExist @testModuleExistParameters -ErrorAction 'Stop'))
            {
                $currentState.Scope = $assignedDscProperties.Scope

                if ($assignedDscProperties.Keys -contains 'Version')
                {
                    $currentState.Version = $assignedDscProperties.Version
                }
            }
        }
        else
        {
            Write-Verbose -Message (
                $this.localizedData.EvaluatingDestination -f $assignedDscProperties.Destination
            )

            $currentState.Destination = ''

            $testModuleExistParameters.Destination = $assignedDscProperties.Destination

            if ((Test-ModuleExist @testModuleExistParameters -ErrorAction 'Stop'))
            {
                $currentState.Destination = $assignedDscProperties.Destination

                if ($assignedDscProperties.Keys -contains 'Version')
                {
                    $currentState.Version = $assignedDscProperties.Version
                }
            }
        }

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced are not in desired state. It is not called if all properties
        are in desired state. The variable $property contain the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $property)
    {
        Start-PSResourceGetBootstrap @property -Force -ErrorAction 'Stop'
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $property)
    {
        # The properties Scope and Destination are mutually exclusive.
        $assertBoundParameterParameters = @{
            BoundParameterList     = $property
            MutuallyExclusiveList1 = @(
                'Scope'
            )
            MutuallyExclusiveList2 = @(
                'Destination'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        if ($property.Keys -contains 'Scope')
        {
            $scopeModulePath = Get-PSModulePath -Scope $property.Scope

            if (-not (Test-Path -Path $scopeModulePath))
            {
                $errorMessage = $this.localizedData.ScopePathInvalid -f $property.Scope, $scopeModulePath

                New-InvalidArgumentException -ArgumentName 'Scope' -Message $errorMessage
            }
        }

        if ($property.Keys -contains 'Destination')
        {
            if (-not (Test-Path -Path $property.Destination))
            {
                $errorMessage = $this.localizedData.DestinationInvalid -f $property.Destination

                New-InvalidArgumentException -ArgumentName 'Destination' -Message $errorMessage
            }
        }

        if ($property.Keys -contains 'Version')
        {
            $isValidVersion = (
                # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
                $property.Version  -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$' -or
                # Need to support the Nuget range syntax as well.
                $property.Version  -match '^[\[(][0-9\.\,]*[\])]$'
            )

            if (-not $isValidVersion)
            {
                $errorMessage = $this.localizedData.VersionInvalid -f $property.Version

                New-InvalidArgumentException -ArgumentName 'Version' -Message $errorMessage
            }
        }
    }
}
