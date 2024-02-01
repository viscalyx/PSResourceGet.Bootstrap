# Contributing to PSResourceGet.Bootstrap

If you are keen to make PSResourceGet.Bootstrap better, why not consider
contributing your work to the project? Every little change helps us make
a better module for everyone to use, and we would love to have contributions
from the community.

## Contribution guidelines

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Documentation

The comment-based help in each public function will be used to automatically
create the documentation and deployed to the GitHub repository wiki.

The comment-based help text can have markdown formatting syntax.

<!-- markdownlint-disable MD013 - Line length -->
Type | Markdown syntax | Example
-- | -- | --
**Parameter reference** | `**ParameterName**` (bold) | **ParameterName**
**Parameter value reference** | `` `'String1'` ``, `` `$true` ``, `` `50` `` (inline code-block) | `'String1'`, `$true`, `50`
**Name reference** (resource, modules, products, or features, etc.) | `_Product Name_` (Italic) | _Product Name_
**Path reference** | `` `C:\\Program Files\\Application` `` | `C:\\Program Files\\Application`
**Filename reference** | `` `log.txt` `` | `log.txt`

<!-- markdownlint-enable MD013 - Line length -->

If using Visual Studio Code to edit Markdown files it can be a good idea
to install the markdownlint extension. It will help to do style checking.
The file [.markdownlint.json](/.markdownlint.json) is prepared with a default
set of rules which will automatically be used by the extension.

## Automatic formatting with VS Code

There is a VS Code workspace settings file within this project with formatting
settings matching the style guideline. That will make it possible inside VS Code
to press SHIFT+ALT+F, or press F1 and choose 'Format document' in the list. The
PowerShell code will then be formatted according to the Style Guideline
(although maybe not complete, but would help a long way).

## Script Analyzer rules

There are several Script Analyzer rules to help with the development and review
process. Rules come from the modules **ScriptAnalyzer**, **DscResource.AnalyzerRules**,
and **Indented.ScriptAnalyzerRules**.

Some rules (but not all) are allowed to be overridden with a justification.

This is an example how to override a rule from the module **ScriptAnalyzer**.

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Because $global:DSCMachineStatus is used to trigger a Restart, either by force or when there are pending changes')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Because $global:DSCMachineStatus is only set, never used (by design of Desired State Configuration)')]
param ()
```

This is an example how to override a rule from the module **Indented.ScriptAnalyzerRules**.

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
param ()
```

## Design patterns

### Localization

Strings should be localized and there is a default localization file for
english language 'en-US'. There can be other languages added as needed.

Read more about this in the [localization style guideline](https://dsccommunity.org/styleguidelines/localization/).

### Public commands

Public commands are are exported in the module manifest. Public functions
should be added as separate files in the folder `source/Public` and the
file name should be `Verb-Noun.ps1`.

### Private commands

Private commands is commands that are used specific and only for commands
in this module. Private functions should be added as separate files
in the folder `source/Private` and the file name should be `Verb-Noun.ps1`.

### Helper commands

If a helper command can be used by more than one module it is preferably
that the helper command is added to the PowerShell module [DscResource.Common](https://github.com/dsccommunity/DscResource.Common).
Once the helper function is in a full release (not preview) then it can be
automatically be used by commands in this module. This is because the
_DscResource.Common_ module is incorporating during the build phase.

### Unit tests

For a review of a Pull Request (PR) to start, all tests must pass without error.
If you need help to figure why some test don't pass, just write a comment in the
Pull Request (PR), or submit an issue, and somebody will come along and assist.

If want to know how to run this module's tests you can look at the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests)

### Integration tests

Integration tests should be written for commands so they can be validated by
the CI.

### Commands

Commands are publicly exported commands from the module, and the source for
commands are located in the folder `./source/Public`.

#### Non-Terminating Error

A non-terminating error should only be used when a command shall be able to
handle (ignoring) an error and continue processing and still give the user
an expected outcome.

With a non-terminating error the user is able to decide whether the command
should throw or continue processing on error. The user can pass the
parameter and value `-ErrorAction 'SilentlyContinue'` to the command  to
ignore the error and allowing the command to continue, for example the
command could then return `$null`. But if the user passes the parameter
and value `-ErrorAction 'Stop'` the same error will throw a terminating
error telling the user the expected outcome could not be achieved.

The below example checks to see if a database exist, if it doesn't a
non-terminating error are called. The user is able to either ignore the
error or have it throw depending on what value the user specifies
in parameter `ErrorAction` (or `$ErrorActionPreference`).

```powershell
if (-not $databaseExist)
{
    $errorMessage = $script:localizedData.MissingDatabase -f $DatabaseName

    Write-Error -Message $errorMessage -Category 'InvalidOperation' -ErrorId 'GS0001' -TargetObject $DatabaseName
}
```

#### Terminating Error

A terminating error is an error that the user are not able to ignore by
passing a parameter to the command (like for non-terminating errors).

If a command shall throw an terminating error then the statement `throw` shall
not be used, neither shall the command `Write-Error` with the parameter
`-ErrorAction Stop`. Always use the method `$PSCmdlet.ThrowTerminatingError()`
to throw a terminating error. The exception is when a `[ValidateScript()]`
has to throw an error, then `throw` must be used.

> [!IMPORTANT]
> Below output assumes `$ErrorView` is set to `'NormalView'` in the
> PowerShell session.

When using `throw` it will fail on the line with the throw statement
making it look like it is that statement inside the function that failed,
which is not correct since it is either a previous command or evaluation
that failed resulting in the line with the `throw` being called. This is
an example when using `throw`:

```plaintext
Exception:
Line |
   2 |  throw 'My error'
     |  ~~~~~~~~~~~~~~~~
     | My error
```

When instead using `$PSCmdlet.ThrowTerminatingError()`:

```powershell
$PSCmdlet.ThrowTerminatingError(
    [System.Management.Automation.ErrorRecord]::new(
        'MyError',
        'GS0001',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        'MyObjectOrValue'
    )
)
```

The result from `$PSCmdlet.ThrowTerminatingError()` shows that the command
failed (in this example `Get-Something`) and returns a clear category and
error code.

```plaintext
Get-Something : My Error
At line:1 char:1
+ Get-Something
+ ~~~~~~~~~~~~~
+ CategoryInfo          : InvalidOperation: (MyObjectOrValue:String) [Get-Something], Exception
+ FullyQualifiedErrorId : GS0001,Get-Something
```
