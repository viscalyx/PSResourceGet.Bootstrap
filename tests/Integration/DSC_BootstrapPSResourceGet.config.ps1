#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName              = 'localhost'
                CertificateFile       = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Bootstraps Microsoft.PowerShell.PSResourceGet to scope CurrentUser.
#>
Configuration DSC_BootstrapPSResourceGet_CurrentUser_Config
{
    Import-DscResource -ModuleName 'PSResourceGet.Bootstrap'

    node $AllNodes.NodeName
    {
        BootstrapPSResourceGet 'Integration_Test'
        {
            IsSingleInstance = 'Yes'
            Scope            = 'CurrentUser'
        }
    }
}
