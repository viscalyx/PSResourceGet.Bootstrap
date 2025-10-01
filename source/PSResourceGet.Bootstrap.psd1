@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'PSResourceGet.Bootstrap.psm1'

    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # ID used to uniquely identify this module
    GUID                 = '98a35d2b-5226-424d-bf7e-efc333d3cd8d'

    # Author of this module
    Author               = 'Viscalyx'

    # Company or vendor of this module
    CompanyName          = 'Viscalyx'

    # Copyright statement for this module
    Copyright            = 'Copyright the PSResourceGet.Bootstrap contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Simplify bootstrapping Microsoft.PowerShell.PSResourceGet on systems.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module
    FunctionsToExport    = @()

    # Cmdlets to export from this module
    CmdletsToExport      = '*'

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    DscResourcesToExport = @()

    RequiredAssemblies   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            # Set to a prerelease string value if the release should be a prerelease.
            Prerelease   = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('PSResourceGet', 'Bootstrap')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/viscalyx/PSResourceGet.Bootstrap/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/viscalyx/PSResourceGet.Bootstrap'

            # A URL to an icon representing this module.
            IconUri      = 'https://avatars.githubusercontent.com/u/53994072'

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
