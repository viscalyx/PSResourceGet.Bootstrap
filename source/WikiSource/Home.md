# Welcome to the PSResourceGet.Bootstrap wiki

<sup>*PSResourceGet.Bootstrap v#.#.#*</sup>

This module tries to solve (in an opinionated way) how to get the module
_Microsoft.PowerShell.PSResourceGet_ onto a system.

Here you will find all the information you need to make use of the latest
release of the PSResourceGet.Bootstrap module. This includes details of the
commands that are available, current capabilities, known issues.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/viscalyx/PSResourceGet.Bootstrap/issues)
of this repository.

## Getting started

### Bootstrap Script

The fastest way to bootstrap the module _Microsoft.PowerShell.PSResourceGet_
is to use the bootstrap script:

```powershell
iwr bit.ly/psresourceget | iex
```

This uses default values and will bootstrap _Microsoft.PowerShell.PSResourceGet_
to the scope `CurrentUser`.

>[!NOTE]
>The bit.ly-link uses URL https://github.com/viscalyx/PSResourceGet.Bootstrap/releases/latest/download/bootstrap.ps1.
>which bounces to the latest full release artifact, e.g.
>https://github.com/viscalyx/PSResourceGet.Bootstrap/releases/download/v0.1.0/bootstrap.ps1.

```powershell
& ([ScriptBlock]::Create((iwr 'bit.ly/psresourceget'))) -Scope 'AllUsers'
```

This will bootstrap the _Microsoft.PowerShell.PSResourceGet_ module to the scope
`AllUsers`.

```powershell
& ([ScriptBlock]::Create((iwr 'bit.ly/psresourceget'))) -Destination 'C:\Modules'
```

This will bootstraps the _Microsoft.PowerShell.PSResourceGet_ module, saving
it to the specified destination path `C:\Modules`.

>[!TIP]
>The bootstrap script has the same parameter sets as the command [`Start-PSResourceGetBootstrap`](https://github.com/dsccommunity/SqlServerDsc/wiki/Start-PSResourceGetBootstrap).

### Download the module from PowerShell Gallery

>[!IMPORTANT]
>Downloading this module from the PowerShell Gallery using `Install-Module`
>and then running the command `Start-PSResourceGetBootstrap` is kind of
>pointless. Then you might as well install the module _Microsoft.PowerShell.PSResourceGet_
>directly. The best use of this method is id _PSResourceGet.Bootstrap_
>is used as a nested module by another module, for example in a Sampler
>templated project. The built module should then import the nested module
>explicitly.

To get started either:

1. Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name PSResourceGet.Bootstrap -Repository PSGallery
```

2. Bootstrap _Microsoft.PowerShell.PSResourceGet_ by running the following command:

```powershell
Start-PSResourceGetBootstrap
```

3. Install a resource using `Install-PSResource`.

```powershell
Install-PSResource -Name 'Sampler'
```

### Powershell

It is recommended to use the latest PowerShell version. The minimum Windows
Management Framework (PowerShell) version required is 5.1.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/viscalyx/PSResourceGet.Bootstrap/blob/main/CHANGELOG.md).
