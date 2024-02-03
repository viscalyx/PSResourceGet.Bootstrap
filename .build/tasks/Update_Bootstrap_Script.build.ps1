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
    function Get-FunctionDefinitionAst
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.String]
            $CommandName,

            [Parameter()]
            [System.String]
            $ModuleContent
        )

        if (-not $PSBoundParameters.ContainsKey('ModuleContent'))
        {
            # Get the command script definition.
            $moduleContent = (Get-Command $CommandName).Module.Definition
        }

        # Parse the script into an AST.
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($ModuleContent, [ref] $null, [ref] $null)

        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $args[0].Name -eq $CommandName
        }

        $functionDefinition = $ast.Find($astFilter, $true)

        return $functionDefinition
    }

    function Get-ParameterAst
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Language.ParamBlockAst]
            $Ast,

            [Parameter(Mandatory = $true)]
            [System.String]
            $ParameterName
        )

        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.ParameterAst] `
            -and $args[0].Name.Extent.Text -eq $ParameterName
        }

        $parameterAst = $Ast.Find($astFilter, $false)

        return $parameterAst
    }

    function Get-ParameterValidationAst
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Language.ParameterAst]
            $Ast
        )

        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.AttributeAst] `
                -and $args[0].TypeName.Name -match 'Validate'
        }

        $validateAttributeAst = $Ast.Find($astFilter, $false)

        return $validateAttributeAst
    }

    function Remove-AstExtentContent
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Language.Ast]
            $Ast,

            [Parameter(Mandatory = $true)]
            [System.String]
            $Script
        )

        $startOffset = $Ast.Extent.StartOffset
        $endOffset = $Ast.Extent.EndOffset

        Write-Debug -Message "Start offset: $startOffset, End offset: $endOffset"

        $beforeAst = $Script.Substring(0, $startOffset)
        $afterAst = $Script.Substring($endOffset)

        return $beforeAst + $afterAst
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

    Write-Build -Color 'DarkGray' -Text "`tParse the parameter block of the Start-PSResourceGetBootstrap command in the built module."

    # Get the function definition of the command Start-PSResourceGetBootstrap command in the built module.
    $functionDefinition = Get-FunctionDefinitionAst -CommandName 'Start-PSResourceGetBootstrap'

    # Need to parse the entire module content to get the correct parameter block.
    $moduleContent = $functionDefinition.Parent.Parent.Extent.Text

    # Get the parameters for the Start-PSResourceGetBootstrap command.
    $parameters = $functionDefinition.Body.ParamBlock.Parameters.Name

    foreach ($parameter in $parameters)
    {
        Write-Build -Color 'DarkGray' -Text "`t`tGet the validation attributes for parameter $parameter."
        $parameterAst = Get-ParameterAst -Ast $functionDefinition.Body.ParamBlock -ParameterName $parameter
        $validationAttributeAst = Get-ParameterValidationAst -Ast $parameterAst

        if ($validationAttributeAst -and $validationAttributeAst.TypeName.Name -eq 'ValidateScript')
        {
            Write-Build -Color 'DarkGray' -Text "`t`t`tRemove the validation script for parameter $parameter."
            $moduleContent = Remove-AstExtentContent -Ast $validationAttributeAst -Script $moduleContent

            # Parse the $moduleContent result to AST to get the correct parameter block, to continue parsing parameters.
            $functionDefinition = Get-FunctionDefinitionAst -CommandName 'Start-PSResourceGetBootstrap' -ModuleContent $moduleContent
        }
    }

    # Parse the $moduleContent result to AST to get the correct parameter block.
    $functionDefinition = Get-FunctionDefinitionAst -CommandName 'Start-PSResourceGetBootstrap' -ModuleContent $moduleContent

    Write-Build -Color 'DarkGray' -Text "`tWrite the parameter block of the bootstrap script."
    $parameterBlockString = "[CmdletBinding(DefaultParameterSetName = 'Scope')]`n" + $functionDefinition.Body.ParamBlock.Extent.Text

    Write-Build -Color 'DarkGray' -Text "`tSet parameters in the bootstrap script"
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder parameters', $parameterBlockString)

    Write-Build -Color 'DarkGray' -Text "`tGet the localization content."
    $localizationContent = Get-Content -Path "$SourcePath/en-US/PSResourceGet.Bootstrap.strings.psd1" -Raw

    Write-Build -Color 'DarkGray' -Text "`t`tRemove the comment-based help from the localization content."
    $regex = [System.Text.RegularExpressions.RegEx]::new(' *<#(?s).*#>\r?\n*', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $localizationContent = $regex.Replace($localizationContent, '')

    Write-Build -Color 'DarkGray' -Text "`tSet localization in the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder localization', "`$script:localizedData = `n$localizationContent")

    Write-Build -Color 'DarkGray' -Text "`tGet the function definition of the Start-PSResourceGetBootstrap command in the built module."
    $functionDefinition = Get-FunctionDefinitionAst -CommandName 'Start-PSResourceGetBootstrap'

    Write-Build -Color 'DarkGray' -Text "`tGet the comment-based help for the Start-PSResourceGetBootstrap function."
    $commentBasedHelp = ($functionDefinition.GetHelpContent()).GetCommentBlock()
    $functionDefinitionString = $functionDefinition.Extent.Text

    Write-Build -Color 'DarkGray' -Text "`tAdd the command Start-PSResourceGetBootstrap to the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder Start-PSResourceGetBootstrap', "$($commentBasedHelp)$($functionDefinitionString)")

    Write-Build -Color 'DarkGray' -Text "`tAdd private helper commands to the bootstrap script."

    $commands = @(
        'Get-EnvironmentVariable'
        'Get-PSModulePath'
        'New-Exception'
        'New-ErrorRecord'
    )

    $functionDefinitionString = ''

    foreach ($command in $commands)
    {
        Write-Build -Color 'DarkGray' -Text "`t`tGet definition for command $Command."

        $functionDefinition = Get-FunctionDefinitionAst -CommandName $command

        $functionDefinitionString += $functionDefinition.Extent.Text
        $functionDefinitionString += "`n"
    }

    Write-Build -Color 'DarkGray' -Text "`tAdding helper commands to the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder helpers', $functionDefinitionString)

    Write-Build -Color 'DarkGray' -Text "`tExport only command Start-PSResourceGetBootstrap from the bootstrap script."
    $builtBootstrapScript = $builtBootstrapScript.Replace('#placeholder export', "Export-ModuleMember -Function 'Start-PSResourceGetBootstrap'")

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

    Write-Debug -Message "Updated bootstrap script:`n$builtBootstrapScript"

    Write-Build -Color 'DarkGray' -Text "`tWrite the bootstrap script to the build output folder."
    Set-Content -Path "$OutputDirectory/bootstrap.ps1" -Value $builtBootstrapScript
}
