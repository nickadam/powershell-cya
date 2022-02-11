function New-CyaConfig {
  <#
  .SYNOPSIS
  Creates CyaConfigs.

  .DESCRIPTION
  A CyaConfig is an encrypted collection of small files or environment variables.
  Items in the CyaConfig can be protected (encrypted to a new file and source file
  deleted or removed from the shell) or unprotected (decrypted and set on the
  shell or written to the file path defined).

  .PARAMETER Name
  [String] The name of the CyaConfig

  .PARAMETER Type
  [String] File or EnvVar (Environment Variable)

  .PARAMETER EnvVarName
  [String] Name of the environment variable

  .PARAMETER EnvVarValue
  [String] Value of the environment variable

  .PARAMETER EnvVarCollection
  [Object] A hashtable or any object with Name and Value

  .PARAMETER File
  [Object] A file or list of files

  .PARAMETER ProtectOnExit
  [Int] Set to 1 ot $True if you want to delete the unprotected files on exit

  .PARAMETER CyaPassword
  [String] The CyaPassword to encrypt and decrypt the CyaConfig, defaults to "Default"

  .PARAMETER Password
  [SecureString] Your password to decrypt the CyaPassword

  .OUTPUTS
  [Object] CyaConfig item status

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  New-CyaConfig

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


  Description
  -----------
  With no parameters specified, the user is prompted for every option. This
  includes setting the default password, which results in a new CyaPassword
  as well as CyaConfig.

  .EXAMPLE
  New-CyaConfig -Name sample -EnvVarName MYVAR -EnvVarValue 12345 -CyaPassword Default
  Enter password for CyaPassword "Default": ********

  Name          : sample
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYVAR
  Status        : Protected


  Description
  -----------
  A single environment variable name and value can be specified. Keep in my the
  value will be in your command history.

  .EXAMPLE
  Get-ChildItem | New-CyaConfig -Name sample -ProtectOnExit $true
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


  Description
  -----------
  A CyaConfig can be created from files in the pipeline. ProtectOnExit, if
  enabled, will attempt to delete unprotected files from the system when the
  shell exists cleanly. File hashes are checked to ensure the file hasn't been
  modified since it was protected.

  .EXAMPLE
  New-CyaConfig -Name sample -File file1.conf -ProtectOnExit $true
  Enter password for CyaPassword "Default": ********

  Name          : sample
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : C:\Users\nickadam\sample\file1.conf
  Status        : Unprotected


  Description
  -----------
  A file or list of files can be provided.

  .EXAMPLE
  "MYVAR", "MYOTHERVAR" | New-CyaConfig -Name sample
  Enter password for CyaPassword "Default": ********

  Name          : sample
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYVAR
  Status        : Unprotected

  Name          : sample
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYOTHERVAR
  Status        : Unprotected


  Description
  -----------
  A CyaConfig can be created from set environment variables.

  .EXAMPLE
  New-CyaConfig -EnvVarCollection (Get-ChildItem Env: | where{$_.Name -like "MY*"}) -Name sample
  Enter password for CyaPassword "Default": ********

  Name          : sample
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYOTHERVAR
  Status        : Unprotected

  Name          : sample
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYVAR
  Status        : Unprotected


  Description
  -----------
  A collection of environment variables can be specified as a hashtable or any
  iterable list of objects with Name and Value.

  #>

  [CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = "SomethingFromPipeline")]
  param(
    [Parameter(Mandatory)]
    [String]$Name,

    [Parameter(Mandatory,
    ParameterSetName="EnvVar")]
    [String]$EnvVarName,

    [Parameter(Mandatory,
    ParameterSetName="EnvVar")]
    [Object]$EnvVarValue,

    [Parameter(Mandatory,
    ParameterSetName="EnvVarCollection")]
    [Object]$EnvVarCollection,

    [Parameter(Mandatory,
    ParameterSetName="FileOrFiles")]
    [Object]$File,

    [Parameter(ParameterSetName="SomethingFromPipeline")]
    [Parameter(ParameterSetName="FileOrFiles")]
    [ValidateSet(0, 1)]
    [Int]$ProtectOnExit = -1,

    [alias("CyaPassword")]
    [String]$CyaPwName="Default",
    [SecureString]$Password,

    [Parameter(ValueFromPipeline,
    DontShow,
    ParameterSetName="SomethingFromPipeline")]
    [Object]$InputObject,

    [ValidateSet("EnvVar", "File")]
    [String]$Type
  )

  begin {
    $InputObjects = @()
  }

  process {
    if($InputObject){
      $InputObjects += $InputObject
    }
  }

  end {
    $CyaPassword = $CyaPwName
    # InputObjects could be a list of files or environment variables
    if($InputObjects){
      $File = $False
      $EnvVarCollection = @()
      ForEach($Item in $InputObjects){
        if($Type -eq "File" -or (Get-Item $Item -ErrorAction SilentlyContinue)){
          if($File){
            Continue
          }
          # must be a list of files
          $File = $InputObjects
        }else{
          # must be a list of environment variables
          $ItemEnvVarName = $Item
          $ItemEnvVarValue = Get-EnvVarValueByName -Name $ItemEnvVarName
          if(-not $ItemEnvVarValue){
            $Message = "The piped item `"$ItemEnvVarName`" is not a file or a " +
            "set environment variable and can't be added to a collection."
            Throw $Message
          }
          $EnvVarCollection += [PSCustomObject]@{
            "Name" = $ItemEnvVarName
            "Value" = $ItemEnvVarValue
          }
        }
      }
    }

    # create new CyaPassword
    if(-not (Get-CyaPassword -Name $CyaPassword -EA SilentlyContinue)){
      Write-Warning "CyaPassword `"$CyaPassword`" not found, creating now with New-CyaPassword."
      if(!$Password){
        $Password = Get-NewPassword
      }
      New-CyaPassword -Name $CyaPassword -Password $Password
    }

    # Attempt to set $Type
    if($EnvVarName -or $EnvVarCollection){
      $Type = "EnvVar"
    }
    if($File){
      $Type = "File"
    }

    $CyaConfigPath = Get-CyaConfigPath
    $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name

    # Check if config already exists
    if(Test-Path $ConfigPath){
      Throw "Config `"$Name`" already exists"
    }

    # Show option for type
    if(-not $Type){
      $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&EnvVar", "&File")
      $Option = $host.UI.PromptForChoice("Config type", "", $Options, 0)
      Switch($Option){
        0 { $Type = "EnvVar"}
        1 { $Type = "File"}
      }
    }

    # Create Environment Variable config
    if($Type -eq "EnvVar"){
      if($EnvVarName -and $EnvVarValue){
        $EnvVarCollection = [PSCustomObject]@{
          "Name" = $EnvVarName
          "Value" = $EnvVarValue
        }
      }
      if($EnvVarName -and $EnvVarSecureString){
        $EnvVarCollection = [PSCustomObject]@{
          "Name" = $EnvVarName
          "Value" = Get-SecureStringText -SecureString $EnvVarSecureString
        }
      }

      # no EnvVar specified, prompt user
      if(-not $EnvVarCollection){
        $Collecting = $True
        $EnvVarCollection = @()
        $n = 0
        while($Collecting){
          $n++
          $EnvVarName = Read-Host -Prompt "Variable $n name (Enter when done)"

          # done collecting
          if(-not $EnvVarName){
            $Collecting = $False
            Continue
          }

          $Message = "$EnvVarName value"

          # check if environment varialbe is currently set
          $SetValue = Get-EnvVarValueByName -Name $EnvVarName
          if($SetValue){
            $Message = "$EnvVarName value [$SetValue]"
          }
          $EnvVarSecureString = Read-Host -AsSecureString -Prompt $Message
          $EnvVarValue = Get-SecureStringText -SecureString $EnvVarSecureString

          # use current environment variable set
          if($SetValue -and (-not $EnvVarValue)){
            $EnvVarValue = $SetValue
          }

          $EnvVar = [PSCustomObject]@{
            "Name" = $EnvVarName
            "Value" = $EnvVarValue
          }
          $EnvVarCollection += $EnvVar
        }
      }

      # nothing to do
      if(-not $EnvVarCollection){
        Write-Warning "Nothing to do"
        return
      }

      if(-not $Password){
        $Password = Read-Host -Prompt "Enter password for CyaPassword `"$CyaPassword`"" -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password

      # convert hashtable to list of objects
      $EnvVarCollectionList = @()
      if($EnvVarCollection.GetType().Name -eq "Hashtable"){
        $EnvVarCollection.Keys | ForEach-Object {
          $EnvVarName = $_
          $EnvVarValue = $EnvVarCollection.$EnvVarName
          $EnvVarCollectionList += [PSCustomObject]@{
            "Name" = $EnvVarName
            "Value" = $EnvVarValue
          }
        }
        $EnvVarCollection = $EnvVarCollectionList
      }

      $Cipherbundle = $EnvVarCollection | ConvertTo-Cipherbundle -Key $Key -Name $Name

      if($Cipherbundle.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = @($Cipherbundle)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = $Cipherbundle
        }
      }
    }

    if($Type -eq "File"){
      # set protect on exit
      if($ProtectOnExit -eq -1){
        $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&No", "&Yes")
        $Message = "Would you like to automatically run Protect-CyaConfig (deletes unencrypted config files) on this config when unloading the Cya module or exiting powershell?"
        $Option = $host.UI.PromptForChoice("Protect on exit", $Message, $Options, 1)
        Switch($Option){
          0 { $ProtectOnExit = 0}
          1 { $ProtectOnExit = 1}
        }
      }

      # no files specified, prompt user
      if(-not $File){
        $File = @()
        $Collecting = $True
        $n = 0
        while($Collecting){
          $n++
          $FilePath = Read-Host -Prompt "File $n path (Enter when done)"
          if($FilePath){
            if(-not (Test-Path $FilePath -PathType Leaf)){
              Throw "File $FilePath not found"
            }
            $File += $FilePath
          }else{
            $Collecting = $False
          }
        }
      }

      # nothing to do
      if(-not $File){
        Write-Warning "Nothing to do"
        return
      }

      # if files were explicitly specified as strings or something, check each one
      $File | ForEach-Object {
        $FilePath = $_
        if(-not (Test-Path $FilePath -PathType Leaf)){
          Throw "File $FilePath not found"
        }
        if((Get-Item $FilePath).Length -eq 0){
          Throw "File $FilePath is empty"
        }
      }

      # get the key
      if(-not $Password){
        $Password = Read-Host -Prompt "Enter password for CyaPassword `"$CyaPassword`"" -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password

      # encrypt all the files
      $FileCollection = $File | Get-Item | ConvertTo-Cipherbundle -Key $Key -Name $Name

      if($FileCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = [Bool]$ProtectOnExit
          "Files" = @($FileCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = [Bool]$ProtectOnExit
          "Files" = $FileCollection
        }
      }
    }

    # nothing to do
    if(-not $CyaConfig){
      Write-Warning "Nothing to do"
      return
    }

    # Create missing directory
    if(-not (Test-Path $CyaConfigPath)){
      mkdir -p $CyaConfigPath | Out-Null
    }

    # write config file
    $CyaConfig | ConvertTo-Json | Out-File -Encoding Default $ConfigPath
    if($PSCmdlet.ShouldProcess("Get-CyaConfig $Name", "", "")){
      Get-CyaConfig -Name $Name -Status
    }
  }
}
