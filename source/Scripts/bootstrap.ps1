# Version v#.#.# (yyyy-MM-dd)

#placeholder parameters

$script:moduleName = 'PSResourceGet.Bootstrap'

Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

New-Module -Name $script:moduleName -ScriptBlock {
    #placeholder localization

    #placeholder Start-PSResourceGetBootstrap
} | Import-Module

Start-PSResourceGetBootstrap @PSBoundParameters
