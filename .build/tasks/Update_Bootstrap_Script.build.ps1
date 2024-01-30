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

    Write-Build -Color 'Magenta' -Text 'Updating bootstrap script.'

    Remove-Item -Path "$OutputDirectory/bootstrap.ps1" -Force -ErrorAction 'SilentlyContinue'

    Write-Build -Color 'DarkGray' -Text "`tCopy the bootstrap script to the build output folder."
    Copy-Item -Path "$SourcePath/Scripts/bootstrap.ps1" -Destination $OutputDirectory

    Write-Build -Color 'DarkGray' -Text "`tGet the content of the bootstrap script."
    $builtBootstrapScript = Get-Content -Path "$OutputDirectory/bootstrap.ps1" -Raw

    Write-Build -Color 'DarkGray' -Text "`tSet version and date in the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('v#.#.#', $ModuleVersion)
    $builtBootstrapScript = $builtBootstrapScript.Replace('yyyy-MM-dd', (Get-Date -Format 'yyyy-MM-dd'))

    Write-Build -Color 'DarkGray' -Text "`tGet the function definition for the Start-PSResourceGetBootstrap function."
    $functionDefinition = Get-StartPSResourceGetBootstrapFunctionDefinition

    Write-Build -Color 'DarkGray' -Text "`t`tGet the parameter block for the Start-PSResourceGetBootstrap function."
    $parameterBlockString = $functionDefinition.Body.ParamBlock.Extent.Text

    Write-Build -Color 'DarkGray' -Text "`tSet parameters in the bootstrap script"
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder parameters', $parameterBlockString)

    Write-Build -Color 'DarkGray' -Text "`tGet the localization content."
    $localizationContent = Get-Content -Path "$SourcePath/en-US/PSResourceGet.Bootstrap.strings.psd1" -Raw

    Write-Build -Color 'DarkGray' -Text "`t`tRemove the comment-based help from the localization content."
    $regex = [System.Text.RegularExpressions.RegEx]::new(' *<#(?s).*#>\r?\n*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $localizationContent = $regex.Replace($localizationContent, '')

    Write-Build -Color 'DarkGray' -Text "`tSet localization in the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder localization', "`$script:localizedData = `n$localizationContent")

    Write-Build -Color 'DarkGray' -Text "`tGet the comment-based help for the Start-PSResourceGetBootstrap function."
    $commentBasedHelp = ($functionDefinition.GetHelpContent()).GetCommentBlock()
    $functionDefinitionString = $functionDefinition.Extent.Text

    Write-Build -Color 'DarkGray' -Text "`tSet comment-based help in the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder Start-PSResourceGetBootstrap', "$($commentBasedHelp)$($functionDefinitionString)")

    Write-Debug -Message "Updated bootstrap script:`n$builtBootstrapScript"

    Write-Build -Color 'DarkGray' -Text "`tNormalize line endings."
    $builtBootstrapScript = $builtBootstrapScript -replace '\r?\n', "`n"

    Write-Build -Color 'DarkGray' -Text "`tRemove single line comments (but keep the top version comment)."
    $regex = [System.Text.RegularExpressions.RegEx]::new('^(?!.*\#\>)(?!.*[Vv]ersion) *#.*\r?\n?$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $builtBootstrapScript = $regex.Replace($builtBootstrapScript, '')

    $settings = @{
        IncludeRules = @('PSPlaceOpenBrace', 'PSUseConsistentIndentation', 'PSUseConsistentWhitespace')
        Rules        = @{
            PSPlaceOpenBrace           = @{
                Enable     = $true
                OnSameLine = $true
            }
            PSUseConsistentIndentation = @{
                Enable              = $true
                IndentationSize     = 2
                PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
                Kind                = 'space'
            }
            PSUseConsistentWhitespace  = @{
                Enable                                  = $true
                CheckInnerBrace                         = $true
                CheckOpenBrace                          = $true
                CheckOpenParen                          = $true
                CheckOperator                           = $true
                CheckPipe                               = $true
                CheckPipeForRedundantWhitespace         = $false
                CheckSeparator                          = $true
                CheckParameter                          = $false
                IgnoreAssignmentOperatorInsideHashTable = $false
            }
        }
    }

    Write-Build -Color 'DarkGray' -Text "`tFormat the bootstrap script."
    $builtBootstrapScript = Invoke-Formatter -ScriptDefinition $builtBootstrapScript -Settings $settings

    Write-Build -Color 'DarkGray' -Text "`tWrite the bootstrap script to the build output folder."
    Set-Content -Path "$OutputDirectory/bootstrap.ps1" -Value $builtBootstrapScript
}
