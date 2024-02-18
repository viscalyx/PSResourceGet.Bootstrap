<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource BootstrapPSResourceGet.
#>

# cSpell: ignore BPSRG
ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class BootstrapPSResourceGet.
    EvaluateModule = Evaluate if the module Microsoft.PowerShell.PSResourceGet is present. (BPSRG0001)
    DestinationInvalid = The destination path '{0}' does not exist. (BPSRG0002)
    ScopePathInvalid = The path '{1}' that was returned for the scope '{0}' does not exist. (BPSRG0003)
    EvaluatingScope = Evaluation if module is present in the scope '{0}'. (BPSRG0004)
    EvaluatingDestination = Evaluating if module is present in the destination path '{0}'. (BPSRG0006)
    VersionInvalid = The version '{0}' is not a valid semantic version or one of the supported NuGet version ranges. (BPSRG0007)
    Bootstrapping = Bootstrapping the module Microsoft.PowerShell.PSResourceGet. (BPSRG0008)
    MissingRequiredParameter = At least one of the parameters 'ModuleScope' or 'Destination' bust be specified. (BPSRG0010)
    ModuleScopeInvalid = The module scope '{0}' is not a valid module scope. The value must be one of "CurrentUser" or "AllUsers". (BPSRG0011)
'@
