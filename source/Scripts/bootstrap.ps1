# Version v#.#.# (yyyy-MM-dd)

#placeholder parameters

$script:moduleName = 'PSResourceGet.Bootstrap'

Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

New-Module -Name $script:moduleName -ScriptBlock {
    #placeholder localization

    #placeholder helpers

    #placeholder Start-PSResourceGetBootstrap

    #placeholder export
} | Import-Module

Start-PSResourceGetBootstrap @PSBoundParameters
