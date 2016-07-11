# Get-MyInProgressWorkItems
Get the ids of your in progress work items from Visual Studio Online and return it as a string to be used in your git commit messages.

## Prerequisites
- cURL installed in place of the default `curl` alias used for `Invoke-WebRequest`. See [this link](http://thesociablegeek.com/azure/using-curl-in-powershell/) for details.

## How to install it
- Download and unzip this repository
- Run Install-Module.bat to install the module on powershell

## How to use it?
It is recommended to register an alias like `inpid` in your PowerShell profile.

### Editing your Powershell profile
To check if you have a powershell profile, enter: `Test-Path $profile`. If it returns False, you need to create a profile.

To create a powershell profile, enter: `New-Item $profile -force -itemtype file`.

To edit your powershell profile, enter: `notepad $profile`.

Insert the following lines to ensure you will have the default `curl` alias removed and the new `inpid` alias registered every time you open the PowerShell console.

```
if (test-path alias:curl) { remove-item alias:curl }
if (test-path alias:curl) { remove-item alias:curl }
if (test-path alias:curl) { remove-item alias:curl }
if (test-path alias:curl) { remove-item alias:curl }

if ((test-path alias:inpid) -eq $false) { new-alias inpid Get-MyInProgressWorkItems }
if ((test-path alias:inpid) -eq $false) { new-alias inpid Get-MyInProgressWorkItems }
if ((test-path alias:inpid) -eq $false) { new-alias inpid Get-MyInProgressWorkItems }
if ((test-path alias:inpid) -eq $false) { new-alias inpid Get-MyInProgressWorkItems }
```

If you need to load your profile manually, enter: `. $profile`.
If you use [Cmder](http://www.cmder.net), see [this](https://github.com/cmderdev/cmder/issues/505).

### Getting your in progress work item ids

In PowerShell, just type `Get-MyInProgressWorkItems`, or `inpid` and inform the required parameters.

A string like `#28333 #28383 #28416 #28417` will be returned, where the numbers represent the ids of your work items currently in progress.

If you have no work items in progress, a null value will be returned.

## Parameterization
In your first call, some parameters must be informed. After that, they are stored in the file `%appdata%\Get-MyInProgressWorkItems\user.config` and are not required anymore.

- Print usage options:
`--help` or `-h`
- Inform your user name:
`--user` or `-u`
- Inform your authentication token/password:
`--password` or `-p`
- Inform your Visual Studio online host:
`--host` or `-h`
- Inform your current project:
`--project` or `-r`
- If informed, do not copy the result to the clipboard:
`--doNotCopyToClipboard` or `-d`
- Inform path of the query used to get the in progress work items in your current project:
`--queryPath` or `-q`
