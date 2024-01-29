param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $BuildModuleOutput = (property BuildModuleOutput (Join-Path $OutputDirectory $BuiltModuleSubdirectory)),

    [Parameter()]
    [System.String]
    $ReleaseNotesPath = (property ReleaseNotesPath (Join-Path $OutputDirectory 'ReleaseNotes.md')),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Updates the bootstrap script before deploy
task Update_Bootstrap_Script {
    function Get-StartPSResourceGetBootstrapFunctionDefinition
    {
        [CmdletBinding()]
        param ()

        # Get the script content
        $moduleContent = Get-Content -Path "$BuiltModuleBase/PSResourceGet.Bootstrap.psm1" -Raw

        # Parse the script into an AST
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($moduleContent, [ref]$null, [ref]$null)

        # Find the Start-PSResourceGetBootstrap function definition
        $functionDefinition = $ast.Find({
            param($node)

            return $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                   $node.Name -eq 'Start-PSResourceGetBootstrap'
        }, $true)

        return $functionDefinition
    }

    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    Remove-Item -Path "$OutputDirectory/bootstrap.ps1" -Force -ErrorAction 'SilentlyContinue'

    # Copy the bootstrap script to the build output folder
    Copy-Item -Path "$SourcePath/Scripts/bootstrap.ps1" -Destination $OutputDirectory

    $builtBootstrapScript = Get-Content -Path "$OutputDirectory/bootstrap.ps1" -Raw

    # Set version and date in the bootstrap script
    $builtBootstrapScript = $builtBootstrapScript.Replace('v#.#.#', $ModuleVersion)
    $builtBootstrapScript = $builtBootstrapScript.Replace('yyyy-MM-dd', (Get-Date -Format 'yyyy-MM-dd'))

    $functionDefinition = Get-StartPSResourceGetBootstrapFunctionDefinition

    #Write-Verbose -Message "Found function definition: $($functionDefinition.Name)" -Verbose
    #Write-Verbose -Message "Found function definition: $(($functionDefinition.GetHelpContent()).GetCommentBlock())" -Verbose
    #Write-Verbose -Message "Found function definition body: $($functionDefinition.Body.Extent.Text)" -Verbose
    #Write-Verbose -Message "Found function definition body: $($functionDefinition.Extent.Text)" -Verbose
    #Write-Verbose -Message "Found function definition body param block: $($functionDefinition.Body.ParamBlock)" -Verbose
    #Write-Verbose -Message "Found function definition body param block: $($functionDefinition.Body.ParamBlock)" -Verbose
    #Write-Verbose -Message "Found function definition body param block parameters: $($functionDefinition.Body.ParamBlock.Parameters)" -Verbose

    $commandParameterBlock = $functionDefinition.Body.ParamBlock

    $parameterBlockString = $commandParameterBlock.Extent.Text

    # Set parameters in the bootstrap script
    #$builtBootstrapScript = $builtBootstrapScript -replace '(\#region parameters)(?s)(.*)(\#endregion parameters)', "`$1`n$($commandParameterBlock.Extent.Text)`n`$3"
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder parameters', $parameterBlockString)

    # # Copy the content of the en-US localized strings file to the 'localization' region in the bootstrap script
    $localizationContent = Get-Content -Path "$SourcePath/en-US/PSResourceGet.Bootstrap.strings.psd1" -Raw

    # Set localization in the bootstrap script
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder localization', "`$script:localizedData = `n$localizationContent")

    $commentBasedHelp = ($functionDefinition.GetHelpContent()).GetCommentBlock()

    $functionDefinitionString = $functionDefinition.Extent.Text

    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder Start-PSResourceGetBootstrap', "$($commentBasedHelp)$($functionDefinitionString)")

    Write-Debug -Message "Updated bootstrap script:`n$builtBootstrapScript"

    Set-Content -Path "$OutputDirectory/bootstrap.ps1" -Value $builtBootstrapScript
}
