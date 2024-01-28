<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the resource
        PSResourceGet.Bootstrap module. This file should only contain localized
        strings for private functions, public command, and classes.
#>

ConvertFrom-StringData @'
    ## Start-PSResourceGetBootstrap
    Start_PSResourceGetBootstrap_Scope_ShouldProcessVerboseDescription = Bootstrapping '{0}' to scope '{1}'.
    Start_PSResourceGetBootstrap_Destination_ShouldProcessVerboseDescription = Bootstrapping '{0}' to destination '{1}'.
    Start_PSResourceGetBootstrap_ShouldProcessVerboseWarning = Are you sure you want to bootstrap '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Start_PSResourceGetBootstrap_ShouldProcessCaption = Bootstrap {0}
    Start_PSResourceGetBootstrap_FailedDownload = Failed to download '{0}' from the PowerShell Gallery.
    Start_PSResourceGetBootstrap_RenamedFailed = Failed to rename the downloaded package '{0}' to '{1}'. Downloaded package has been removed.
    Start_PSResourceGetBootstrap_ExpandFailed = Failed to expand the (renamed) downloaded package '{0}'. Downloaded package has been removed.
    Start_PSResourceGetBootstrap_Scope_SaveModule = Specified scope is {0}, saving the module to destination {1}.
    Start_PSResourceGetBootstrap_Destination_SaveModule = Specified a specific location, saving the module to destination {0}.
    Start_PSResourceGetBootstrap_AlreadyInUse = {0} is already available and imported into the session from the destination path. If there is a need to refresh the module, open a new session and run the command again.
    Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessVerboseDescription = Saving '{0}' to scope '{1}'.
    Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessVerboseWarning = Are you sure you want to save '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Start_PSResourceGetBootstrap_CompatibilityModule_ShouldProcessCaption = Saving {0}
'@
