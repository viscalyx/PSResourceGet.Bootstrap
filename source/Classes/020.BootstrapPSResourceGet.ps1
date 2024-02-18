<#
    .SYNOPSIS
        The `BootstrapPSResourceGet` DSC resource is used to bootstrap the module
        Microsoft.PowerShell.PSResourceGet to the specified location.

    .DESCRIPTION
        The `BootstrapPSResourceGet` DSC resource is used to bootstrap the module
        Microsoft.PowerShell.PSResourceGet to the specified location.

        It supports two parameter sets: 'Destination' and 'Scope'. The 'Destination'
        parameter set allows you to specify a specific location to save the module,
        while the 'ModuleScope' parameter set saves the module to the appropriate
        `$env:PSModulePath` location based on the specified scope ('CurrentUser'
        or 'AllUsers').

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

    .PARAMETER IsSingleInstance
        Specifies that only a single instance of the resource can exist in one and
        the same configuration. Must always be set to the value `Yes`.

    .PARAMETER Destination
        Specifies the destination path where the module should be saved. This parameter
        is mandatory when using the 'Destination' parameter set. The path must be a valid
        container. This parameter may not be used at the same time as the parameter
        `ModuleScope`.

    .PARAMETER ModuleScope
        Specifies the scope for saving the module. This parameter is used when using the
        'ModuleScope' parameter set. The valid values are 'CurrentUser' and 'AllUsers'. The
        default value is 'CurrentUser'. This parameter may not be used at the same time
        as the parameter Destination.

    .PARAMETER Version
        Specifies the version of the Microsoft.PowerShell.PSResourceGet module to download.
        If not specified, the latest version will be downloaded.

    .EXAMPLE
        Invoke-DscResource -ModuleName PSResourceGet.Bootstrap -Name BootstrapPSResourceGet -Method Get -Property @{
            IsSingleInstance = 'Yes'
            ModuleScope      = 'CurrentUser'
        }

        This example shows how to call the resource using Invoke-DscResource. This
        example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving
        it to the appropriate location based on the scope `'CurrentUser'`.

    .EXAMPLE
        Invoke-DscResource -ModuleName PSResourceGet.Bootstrap -Name BootstrapPSResourceGet -Method Get -Property @{
            IsSingleInstance = 'Yes'
            ModuleScope      = 'CurrentUser'
            Version          = '1.0.2'
        }

        This example shows how to call the resource using Invoke-DscResource. This
        example bootstraps the Microsoft.PowerShell.PSResourceGet module with version
        1.0.2, saving it to the appropriate location based on the scope `'CurrentUser'`.

    .EXAMPLE
        Invoke-DscResource -ModuleName PSResourceGet.Bootstrap -Name BootstrapPSResourceGet -Method Get -Property @{
            IsSingleInstance = 'Yes'
            Destination      = '/path/to/destination'
        }

        This example shows how to call the resource using Invoke-DscResource. This
        example bootstraps the Microsoft.PowerShell.PSResourceGet module, saving it
        to the path specified in the parameter `Destination`.
#>
[DscResource(RunAsCredential = 'Optional')]
class BootstrapPSResourceGet : ResourceBase
{
    [DscProperty(Key)]
    [SingleInstance]
    $IsSingleInstance

    # The Destination is evaluated if exist in AssertProperties().
    [DscProperty()]
    [System.String]
    $Destination

    <#
        The ModuleScope is evaluated in AssertProperties(). This parameter cannot
        use the ValidateSet() attribute since it is not possible to set a null value,
        unless it is set to [ValidateSet('CurrentUser', 'AllUsers', $null)] .

        The parameter name Scope could not be used as it is a reserved keyword in
        PowerShell DSC, if used it throws an error when parsing a configuration.
    #>
    [DscProperty()]
    [System.String]
    $ModuleScope

    # The Version is evaluated if exist in AssertProperties().
    [DscProperty()]
    [System.String]
    $Version

    [DscProperty(NotConfigurable)]
    [PSResourceGetBootstrapReason[]]
    $Reasons

    BootstrapPSResourceGet () : base ($PSScriptRoot)
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
        Write-Debug -Message (
            'Enter GetCurrentState. Parameters: {0}' -f ($keyProperty | ConvertTo-Json -Compress)
        )

        Write-Verbose -Message $this.localizedData.EvaluateModule

        $currentState = @{
            IsSingleInstance = [SingleInstance]::Yes
        }

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

            $currentState.Version = $null
        }

        # If it is ModuleScope wasn't specified, then destination was specified.
        if ($assignedDscProperties.Keys -contains 'ModuleScope')
        {
            Write-Verbose -Message (
                $this.localizedData.EvaluatingScope -f $assignedDscProperties.ModuleScope
            )

            $currentState.ModuleScope = $null

            $testModuleExistParameters.Scope = $assignedDscProperties.ModuleScope

            if ((Test-ModuleExist @testModuleExistParameters -ErrorAction 'Stop'))
            {
                $currentState.ModuleScope = $assignedDscProperties.ModuleScope

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

            $currentState.Destination = $null

            $testModuleExistParameters.Path = $assignedDscProperties.Destination

            if ((Test-ModuleExist @testModuleExistParameters -ErrorAction 'Stop'))
            {
                $currentState.Destination = $assignedDscProperties.Destination

                if ($assignedDscProperties.Keys -contains 'Version')
                {
                    $currentState.Version = $assignedDscProperties.Version
                }
            }
        }

        Write-Debug -Message 'Exit GetCurrentState'

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
        Write-Debug -Message (
            'Enter Modify. Parameters: {0}' -f ($property | ConvertTo-Json -Compress)
        )

        Write-Verbose -Message $this.localizedData.Bootstrapping

        if ($property.Keys -contains 'ModuleScope')
        {
            $property.Scope = $property.ModuleScope

            $property.Remove('ModuleScope')
        }

        Write-Debug -Message "Start-PSResourceGetBootstrap Parameters:`n$($property | Out-String)"

        Start-PSResourceGetBootstrap @property -Force -ErrorAction 'Stop'

        Write-Debug -Message 'Exit Modify'
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $property)
    {
        Write-Debug -Message (
            'Enter AssertProperties. Parameters: {0}' -f ($property | ConvertTo-Json -Compress)
        )

        # The properties ModuleScope and Destination are mutually exclusive.
        $assertBoundParameterParameters = @{
            BoundParameterList     = $property
            MutuallyExclusiveList1 = @(
                'ModuleScope'
            )
            MutuallyExclusiveList2 = @(
                'Destination'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        if ($property.Keys -notcontains 'ModuleScope' -and $property.Keys -notcontains 'Destination')
        {
            $errorMessage = $this.localizedData.MissingRequiredParameter

            New-InvalidArgumentException -ArgumentName 'ModuleScope, Destination' -Message $errorMessage
        }

        if ($property.Keys -contains 'ModuleScope')
        {
            <#
                It is not possible to set a null value to the parameter ModuleScope
                when it has a [ValidateSet()] unless it would be set to
                [ValidateSet('CurrentUser', 'AllUsers', $null)]. But that would
                give a strange output if giving the wrong value to the parameter:
                E.g.

                    'The argument "CurrentUser2" does not belong to the set
                    "CurrentUser,AllUsers," specified by the ValidateSet
                    attribute.'
            #>
            if ($property.ModuleScope -notin ('CurrentUser', 'AllUsers'))
            {
                $errorMessage = $this.localizedData.ModuleScopeInvalid -f $property.ModuleScope

                New-InvalidArgumentException -ArgumentName 'ModuleScope' -Message $errorMessage
            }

            Write-Verbose -Message "Evaluating if module is present in the scope '$($property.ModuleScope)'" -Verbose
            $scopeModulePath = Get-PSModulePath -Scope $property.ModuleScope

            Write-Verbose -Message (
                'MyDocuments: {0}' -f [Environment]::GetFolderPath('MyDocuments')
            )

            # Write-Verbose -Message (
            #     '$IsCoreCLR: {0}' -f (if( $IsCoreCLR) { 'True' } else { 'False' })
            # )

            Write-Verbose -Message "The path that was returned for the scope '$($property.ModuleScope)' is '$scopeModulePath'" -Verbose

            if ([System.String]::IsNullOrEmpty($scopeModulePath) -or -not (Test-Path -Path $scopeModulePath))
            {
                $errorMessage = $this.localizedData.ScopePathInvalid -f $property.ModuleScope, $scopeModulePath

                New-InvalidArgumentException -ArgumentName 'ModuleScope' -Message $errorMessage
            }
        }

        if ($property.Keys -contains 'Destination')
        {
            if ([System.String]::IsNullOrEmpty($property.Destination) -or -not (Test-Path -Path $property.Destination))
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

        Write-Debug -Message 'Exit AssertProperties'
    }
}
