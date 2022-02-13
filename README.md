# PowerShell-CYA
Ciphertext Your Assets

Storing credentials in plain text files is generally considered a bad idea. But
chances are, if you work in DevOps, you may have a few credential files on your
system. Or perhaps you store your secrets as environment variables.

A significant vector in supply chain attacks leverages credential stealing
malware to gain access to your development pipeline. Keeping your secrets in a
"protected by default" mode significantly reduces the likelihood of a successful
attack.

CYA aims to protect the config files and environment variables you use. It does
so by encrypting the files and environment variable values you want to protect.
Then you can simply encrypt and decrypt using `Protect-CyaConfig` and
`Unprotect-CyaConfig`.

CYA also helps you manage different credentials for different environments.
```
PS > New-CyaConfig AWSTest
[...]
PS > New-CyaConfig AWSProd
[...]

PS > Unprotect-CyaConfig AWSTest
Enter password for CyaPassword "Default": *********
```

## Quick start

### Install CYA
```
Install-Module Cya
```

Once installed the following functions are exported and available.
- New-CyaConfig
- Get-CyaConfig
- Protect-CyaConfig (alias pcya)
- Unprotect-CyaConfig (alias ucya)
- Rename-CyaConfig
- Remove-CyaConfig
- New-CyaPassword
- Get-CyaPassword
- Rename-CyaPassword
- Remove-CyaPassword

### Create a config

CYA makes protecting environment variables easy. One big problem with secrets
as environment variables is setting them without exposing them in your command
history. CYA accomplishes this by using PowerShell's `Read-Host -AsSecureString`
To create a new CyaConfig use `New-CyaConfig` and follow the prompts.

```
PS > New-CyaConfig

cmdlet New-CyaConfig at command pipeline position 1
Supply values for the following parameters:
Name: sample
WARNING: CyaPassword "Default" not found, creating now with New-CyaPassword.
Enter new password: ********
Confirm new password: ********

Config type
[E] EnvVar  [F] File  [?] Help (default is "E"):
Variable 1 name (Enter when done): MYVAR
MYVAR value: *****
Variable 2 name (Enter when done): MYOTHERVAR
MYOTHERVAR value: *****
Variable 3 name (Enter when done):

Name          : sample
Type          : EnvVar
CyaPassword   : Default
ProtectOnExit : True
Item          : MYVAR
Status        : Protected

Name          : sample
Type          : EnvVar
CyaPassword   : Default
ProtectOnExit : True
Item          : MYOTHERVAR
Status        : Protected
```

You can configure CYA to automatically delete unencrypted files when you exit
PowerShell using the `-ProtectOnExit` flag. And when you exit PowerShell, or
remove the Module, the file will be deleted. Keep in mind you have to exit
cleanly using the `exit` command or `ctrl + d` (Linux) for this to work.

```
PS > Get-ChildItem | New-CyaConfig -Name sample -ProtectOnExit $true
Enter password for CyaPassword "Default": ********

Name          : sample
Type          : File
CyaPassword   : Default
ProtectOnExit : True
Item          : C:\Users\nickadam\sample\file1.conf
Status        : Unprotected

Name          : sample
Type          : File
CyaPassword   : Default
ProtectOnExit : True
Item          : C:\Users\nickadam\sample\file2.json
Status        : Unprotected
```

### Use your config

Protect (delete) and unprotect (decrypt) your secrets.

```
Unprotect-CyaConfig
[... do what you need to do ...]
Protect-CyaConfig
```

The alias `ucya` and `pcya` are exported for convenience
```
ucya
[... do what you need to do ...]
pcya
```



## Automatic warnings

CYA presents a warning if any config items are unprotected when the CYA module
loads. You can choose to see this warning every time you open a shell by adding
`Import-Module Cya` to your [PowerShell Profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.2).

You can also suppress these warnings by setting the environment variable
`CYA_DISABLE_UNPROTECTED_MESSAGE` to `$True`.

## Different passwords

CYA supports using different passwords on different CyaConfigs using the
`-CyaPassword` parameter. The `New-CyaConfig` and `New-CyaPassword` functions
use "Default" by default.

## Security
CyaConfigs and CyaPasswords are encrypted using AES-256-CBC and can be moved to
any system. Your password is all that's needed to decrypt (so make it a good one).

The contents of files and environment variable values are validated using a salted
SHA256 hash. If you unprotect a file and modify it, the file's hash no longer
matches the hash stored in the config. CYA will not delete the file and will
instead show a warning that the file path conflicts. If you wish to protect a
modified file, use `New-CyaConfig` again.

## CYAPATH and backups

By Default CYA will store configs, passwords, and encrypted files in a `.cya`
folder in your `$Home` (`~`). You can change this location to wherever you like
by setting the environment variable `CYAPATH` to you desired location. You may
want to use a cloud synced folder or any location that you can backup. Or you
can just backup the defualt `.cya` folder.

## Modifying CyaConfigs

Configs and Passwords in CYA are largely immutable but that doesn't mean you
can't change things. For example, if you want to change your password, you can
follow these steps to create a new CyaPassword, new CyaConfig, and remove the old.
```
Rename-CyaPassword -Name Default -NewName OldDefault

Rename-CyaConfig -Name MyConfig -NewName OldMyConfig

New-CyaPassword -Name Default

Unprotect-CyaConfig -Name OldMyConfig

New-CyaConfig -Name MyConfig -CyaPassword Default
[... Add the files or environment variables from OldMyConfig ...]

Protect-CyaConfig MyConfig

Remove-CyaConfig -Name OldMyConfig

Remove-CyaPassword -Name OldDefault
```

## More help
Help documentation is available for each function in CYA.
```
Help New-CyaConfig
```

## Development
### Running tests

Tests are written in the [pester](https://pester.dev/) test framework.

```
Install-Module pester
git clone https://github.com/nickadam/powershell-cya.git
cd powershell-cya
Invoke-Pester
```

### Static code analysis
```
Install-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -Recurse .\Cya\
```

### Code coverage reports

Install ReportGenerator.

```
Find-Package ReportGenerator -ProviderName "nuget" -Source "https://nuget.org/api/v2" | Install-Package -Scope CurrentUser
```

Identify the location of the relevant ReportGenerator.exe. In my case:
```
$RG="$LOCALAPPDATA\PackageManagement\NuGet\Packages\ReportGenerator.5.0.4\tools\net6.0\ReportGenerator.exe"
```

Generate a `coverage.xml` file with pester.
```
Invoke-Pester -CodeCoverage ".\Cya\*" -CodeCoverageOutputFileFormat JaCoCo
```

Generate code coverage report pages.
```
& $RG -reports:coverage.xml -targetdir:.\Coverage -sourcedirs:.\Cya
```
Review the beautiful report.
```
start .\Coverage\index.html
```
