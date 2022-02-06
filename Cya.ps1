# Ciphertext Your Assets

function Get-CyaPasswordPath {
  $Base = Join-Path -Path $Home -ChildPath ".cya"
  if($Env:CYAPATH){
    $Base = $Env:CYAPATH
  }
  return Join-Path -Path $Base -ChildPath "passwords"
}

function Get-CyaConfigPath {
  $Base = Join-Path -Path $Home -ChildPath ".cya"
  if($Env:CYAPATH){
    $Base = $Env:CYAPATH
  }
  return Join-Path -Path $Base -ChildPath "configs"
}

function Get-Sha256Hash {
  param($File, $String, $Salt)

  $Sha256 = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")

  if($File){
    $File = Get-Item $File -ErrorAction Stop
    if($Salt){
      $FileBytes = [System.IO.File]::ReadAllBytes($File)
      $SaltBytes = [System.Text.Encoding]::UTF8.getBytes($Salt)
      $hashBytes = $Sha256.ComputeHash($SaltBytes + $FileBytes)
      $hash = [System.BitConverter]::ToString($hashBytes)
      $hash.toLower() -replace "-", ""
    }else{
      # just file path, use get-filehash
      (Get-FileHash $File).Hash.toLower()
    }
  }elseif($String){
    if($Salt){
      $String = $Salt + $String
    }
    $hashBytes = $Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))
    $hash = [System.BitConverter]::ToString($hashBytes)
    $hash.toLower() -replace "-", ""
  }
}

function Get-Base64FromFile {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$File)
  $File = Get-Item $File -ErrorAction Stop
  $FileBytes = [System.IO.File]::ReadAllBytes($File)
  [System.Convert]::ToBase64String($FileBytes)
}

function Get-RandomString {
  param($Length=64)
  $chars = "ABCDEFGHKLMNOPRSTUVWXYZabcdefghiklmnoprstuvwxyz0123456789".toCharArray()
  $String = ""
  while($String.Length -lt $Length){
    $String += $chars | Get-Random
  }
  $String
}

function Get-SecureStringText {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$SecureString)
  (New-Object PSCredential ".",$SecureString).GetNetworkCredential().Password
}

function Get-EncryptedAnsibleVaultString {
  param($String, $Key)
  if($String){
    $Password = ConvertTo-SecureString -String $Key -AsPlainText
    Get-EncryptedAnsibleVault -Value $String -Password $Password
  }
}

function Get-DecryptedAnsibleVaultString {
  param($CipherTextString, $Key)
  if($CipherTextString){
    $Password = ConvertTo-SecureString -String $Key -AsPlainText
    $TempFile = New-TemporaryFile
    $CipherTextString | Out-File -Encoding Default $TempFile
    Get-DecryptedAnsibleVault -Path $TempFile -Password $Password
    Remove-Item $TempFile
  }
}

function ConvertFrom-Cipherbundle {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle, $Key)
  process {
    if($Cipherbundle.Type -eq "EnvVar"){
      $Value = Get-DecryptedAnsibleVaultString -CipherTextString $Cipherbundle.Ciphertext -Key $Key
      [System.Environment]::SetEnvironmentVariable($Cipherbundle.Name, $Value)
    }
    if($Cipherbundle.Type -eq "File"){
      $FilePath = $Cipherbundle.FilePath
      if(Test-Path $FilePath -PathType Leaf){
        Write-Error "File $FilePath already exists" -ErrorAction Stop
      }else{
        $Base64 = Get-DecryptedAnsibleVaultString -CipherTextString $Cipherbundle.Ciphertext -Key $Key
        $FileBytes = [System.Convert]::FromBase64String($Base64)
        [System.IO.File]::WriteAllBytes($FilePath, $FileBytes)
        Get-Item $FilePath
      }
    }
  }
}

function ConvertTo-Cipherbundle {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Item, $Key, $Name)
  process {
    if($Item.GetType().Name -eq "FileInfo"){
      $Salt = Get-RandomString
      $Hash = Get-Sha256Hash -File $Item -Salt $Salt
      $Base64 = Get-Base64FromFile -File $Item
      $Ciphertext = Get-EncryptedAnsibleVaultString -String $Base64 -Key $Key
      [PSCustomObject]@{
        "Type" = "File"
        "FilePath" = $Item.FullName
        "Salt" = $Salt
        "Hash" = $Hash
        "Ciphertext" = $Ciphertext
      }
    }
    if($Item.GetType().Name -eq "PSCustomObject"){
      $Salt = Get-RandomString
      $Hash = Get-Sha256Hash -String $Item.Value -Salt $Salt
      [PSCustomObject]@{
        "Type" = "EnvVar"
        "Name" = $Item.Name
        "Salt" = $Salt
        "Hash" = $Hash
        "Ciphertext" = Get-EncryptedAnsibleVaultString -String $Item.Value -Key $Key
      }
    }
  }
}

function Confirm-CipherbundleFileHash {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  $Salt = $Cipherbundle.Salt
  $Hash = Get-Sha256Hash -File $Cipherbundle.FilePath -Salt $Salt
  $Hash -eq $Cipherbundle.Hash
}

function Confirm-CipherbundleEnvVarHash {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  $Name = $Cipherbundle.Name
  $Salt = $Cipherbundle.Salt
  $String = Get-EnvVarValueByName -Name $Name
  if(-not $String){
    return $False
  }
  $Hash = Get-Sha256Hash -String $String -Salt $Salt
  $Hash -eq $Cipherbundle.Hash
}

function Get-EnvVarValueByName {
  param($Name)
  Get-ChildItem Env: | ForEach {
    if($_.Name -eq $Name){
      $_.Value
    }
  }
}

function Get-ProtectionStatus {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  process{
    $Status = "Protected"
    if($Cipherbundle.Type -eq "File"){
      if(Get-Item $Cipherbundle.FilePath -ErrorAction SilentlyContinue){
        if($Cipherbundle | Confirm-CipherbundleFileHash){
          $Status = "Unprotected"
        }
      }
      [PSCustomObject]@{
        "Type" = $Cipherbundle.Type
        "FilePath" = $Cipherbundle.FilePath
        "Status" = $Status
      }
    }
    if($Cipherbundle.Type -eq "EnvVar"){
      if($Cipherbundle | Confirm-CipherbundleEnvVarHash){
        $Status = "Unprotected"
      }
      [PSCustomObject]@{
        "Type" = $Cipherbundle.Type
        "Name" = $Cipherbundle.FilePath
        "Status" = $Status
      }
    }
  }
}

function Get-NewPassword {
  $password1 = ""
  while(-not $password1){
    Write-Host -NoNewline "Enter new password: "
    $Password = Read-Host -AsSecureString
    $password1 = Get-SecureStringText -SecureString $Password
  }

  $password2 = ""
  while(-not $password2){
    Write-Host -NoNewline "Confirm new password: "
    $confirm = Read-Host -AsSecureString
    $password2 = Get-SecureStringText -SecureString $confirm
  }

  if($password1 -ne $password2){
    Write-Error -Message "Passwords do not match" -ErrorAction Stop
  }
  return $Password
}

function New-CyaPassword {
  param($Name="Default", $Password)

  $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name

  if(Test-Path $PasswordPath){
    Write-Error -Message "Password $Name already exists" -ErrorAction Stop
  }

  if(!$Password){
    $Password = Get-NewPassword
  }

  if(-not (Test-Path (Get-CyaPasswordPath))){
    mkdir -p (Get-CyaPasswordPath) | Out-Null
  }

  Get-EncryptedAnsibleVault -Value (Get-RandomString) -Password $Password | Out-File -Encoding Default $PasswordPath
}

function Get-CyaPassword {
  [CmdletBinding()]
  param($Name)
  if(-not (Test-Path (Get-CyaPasswordPath))){
    return
  }
  if($Name){
    $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name
    if(Test-Path $PasswordPath -PathType Leaf){
      Get-Item $PasswordPath
    }else{
      Write-Error -Message "CyaPassword `"$Name`" not found"
    }
  }else{
    Get-ChildItem (Get-CyaPasswordPath)
  }
}

function New-CyaConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [ValidateSet("EnvVar", "File")]
    $Type,

    $EnvVarName,
    $EnvVarValue,
    $EnvVarSecureString,
    $EnvVarCollection,

    [Parameter(ValueFromPipeline)]
    $File,

    [ValidateSet($True, $False, 1, 0)]
    $ProtectOnExit,

    $CyaPassword="Default",
    $Password
  )

  begin {
    $Items = @()
  }

  process {
    if($File){
      $Items += $File
    }
  }

  end {
    # Items could be a list of files or environment variables
    if($Items){
      $File = $False
      $EnvVarCollection = @()
      ForEach($Item in $Items){
        if(Get-Item $Item -ErrorAction SilentlyContinue){
          # must be a list of files
          $File = $Items
        }else{
          # must be a list of environment variables
          $ItemEnvVarName = $Item
          $ItemEnvVarValue = Get-EnvVarValueByName -Name $ItemEnvVarName
          if(-not $ItemEnvVarValue){
            $Message = "The piped item `"$ItemEnvVarName`" is not a file or a " +
            "set environment variable and can't be added to a collection."
            Write-Error $Message -ErrorAction Stop
          }
          $EnvVarCollection += [PSCustomObject]@{
            "Name" = $ItemEnvVarName
            "Value" = $ItemEnvVarValue
          }
        }
      }
    }

    if(-not (Get-CyaPassword -Name $CyaPassword -EA SilentlyContinue)){
      Write-Warning "CyaPassword `"$CyaPassword`" password not found, creating now with New-CyaPassword."
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

    # normalize protect on exit
    if($ProtectOnExit -eq 1){
      $ProtectOnExit = $True
    }
    if($ProtectOnExit -eq 0){
      $ProtectOnExit = $False
    }

    # Show option for type
    if(-not $Type){
      $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&EnvVar", "&File")
      $Option = $host.UI.PromptForChoice("Config type:", "", $Options, 0)
      Switch($Option){
        0 { $Type = "EnvVar"}
        1 { $Type = "File"}
      }
    }

    $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Name

    # Check if config already exists
    if(Test-Path $ConfigPath){
      Write-Error -Message "Config `"$Name`" already exists" -ErrorAction Stop
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
          Write-Host -NoNewline "Variable $n name (Enter when done): "
          $EnvVarName = Read-Host
          if($EnvVarName){
            $SetValue = Get-EnvVarValueByName -Name $EnvVarName
            if($SetValue){
              Write-Host -NoNewline "$EnvVarName value [$SetValue]: "
            }else{
              Write-Host -NoNewline "$EnvVarName value : "
            }
            $EnvVarSecureString = Read-Host -AsSecureString
            $EnvVarValue = Get-SecureStringText -SecureString $EnvVarSecureString
            if($SetValue -and (-not $EnvVarValue)){
              $EnvVarValue = $SetValue
            }
            $EnvVar = [PSCustomObject]@{
              "Name" = $EnvVarName
              "Value" = $EnvVarValue
            }
            $EnvVarCollection += $EnvVar
          }else{
            $Collecting = $False
          }
        }
      }

      # nothing to do
      if(-not $EnvVarCollection){
        return
      }

      if(-not $Password){
        Write-Host -NoNewline "Enter password for CyaPassword `"$CyaPassword`": "
        $Password = Read-Host -AsSecureString
      }
      $Key = Get-DecryptedAnsibleVault -Path (Get-CyaPassword -Name $CyaPassword) -Password $Password

      # convert hashtable to list of objects
      $EnvVarCollectionList = @()
      if($EnvVarCollection.GetType().Name -eq "Hashtable"){
        $EnvVarCollection.Keys | ForEach {
          $EnvVarName = $_
          $EnvVarValue = $EnvVarCollection.$EnvVarName
          $EnvVarCollectionList += [PSCustomObject]@{
            "Name" = $EnvVarName
            "Value" = $EnvVarValue
          }
        }
        $EnvVarCollection = $EnvVarCollectionList
      }

      $CyaConfigEnvVarCollection = $EnvVarCollection | ConvertTo-Cipherbundle -Key $Key

      if($CyaConfigEnvVarCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = @($CyaConfigEnvVarCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "EnvVar"
          "CyaPassword" = $CyaPassword
          "Variables" = $CyaConfigEnvVarCollection
        }
      }

      if(-not (Test-Path (Get-CyaConfigPath))){
        mkdir -p (Get-CyaConfigPath) | Out-Null
      }
    }

    if($Type -eq "File"){
      if($ProtectOnExit -eq $Null){
        $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
        $Message = "Would you like to automatically run Protect-CyaConfig (deletes unencrypted config files) on this config when unloading the Cya module or exiting powershell?"
        $Option = $host.UI.PromptForChoice("Protect on exit:", $Message, $Options, 0)
        Switch($Option){
          0 { $ProtectOnExit = $True}
          1 { $ProtectOnExit = $False}
        }
      }

      # no files specified, prompt user
      if(-not $File){
        $File = @()
        $Collecting = $True
        $n = 0
        while($Collecting){
          $n++
          Write-Host -NoNewline "File $n path (Enter when done): "
          $FilePath = Read-Host
          if($FilePath){
            if(-not (Test-Path $FilePath -PathType Leaf)){
              Write-Error -Message "File $FilePath not found" -ErrorAction Stop
            }
            $File += $FilePath
          }else{
            $Collecting = $False
          }
        }
      }

      # nothing to do
      if(-not $File){
        return
      }

      # Check all files exist
      $File | ForEach {
        $FilePath = $_
        if(-not (Test-Path $FilePath -PathType Leaf)){
          Write-Error -Message "File $FilePath not found" -ErrorAction Stop
        }
      }

      # get the key
      if(-not $Password){
        Write-Host -NoNewline "Enter password for CyaPassword `"$CyaPassword`": "
        $Password = Read-Host -AsSecureString
      }
      $Key = Get-DecryptedAnsibleVault -Path (Get-CyaPassword -Name $CyaPassword) -Password $Password

      # # encrypt all the files
      $FileCollection = $File | Get-Item | ConvertTo-Cipherbundle -Key $Key

      if($FileCollection.length -eq 1){
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = $ProtectOnExit
          "Files" = @($FileCollection)
        }
      }else{
        $CyaConfig = [PSCustomObject]@{
          "Type" = "File"
          "CyaPassword" = $CyaPassword
          "ProtectOnExit" = $ProtectOnExit
          "Files" = $FileCollection
        }
      }
    }

    # nothing to do
    if(-not $CyaConfig){
      return
    }

    # write config file
    $CyaConfig | ConvertTo-Json -Depth 3 | Out-File -Encoding Default $ConfigPath
    Get-CyaConfig -Name $Name
  }
}

function Get-CyaConfig {
  [CmdletBinding()]
  param($Name, [Switch]$Status, [Switch]$Unprotected)
  if(-not (Test-Path (Get-CyaConfigPath))){
    return
  }

  function Get-ConfigSummary {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)]$Config)
    $Type = $Config.Type
    $ProtectOnExit = $Config.ProtectOnExit
    $Variables = ''
    $Files = ''
    if($Type -eq "EnvVar"){
      $ProtectOnExit = $True
      $Variables = $Config.Variables.Name
    }
    if($Type -eq "File"){
      $Files = $Config.Files.FilePath
    }
    [PSCustomObject]@{
      "Type" = $Type
      "CyaPassword" = $Config.CyaPassword
      "ProtectOnExit" = $ProtectOnExit
      "Variables" = $Variables
      "Files" = $Files
    }
  }

  # error if not found
  if($Name){
    $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Name
    if(-not (Test-Path $ConfigPath -PathType Leaf)){
      Write-Error -Message "CyaConfig `"$Name`" not found" -ErrorAction Stop
    }
  }

  ForEach($Config in Get-ChildItem (Get-CyaConfigPath)){
    $ConfigName = $Config.Name
    if($Name -and ($ConfigName -ne $Name)){
      Continue
    }
    $Config = $Config | Get-Content | ConvertFrom-Json -Depth 3
    $ConfigSummary = $Config | Get-ConfigSummary
    if(-not ($Status -or $Unprotected)){
      [PSCustomObject]@{
        "Name" = $ConfigName
        "Type" = $ConfigSummary.Type
        "CyaPassword" = $ConfigSummary.CyaPassword
        "ProtectOnExit" = $ConfigSummary.ProtectOnExit
        "Variables" = $ConfigSummary.Variables
        "Files" = $ConfigSummary.Files
      }
    }else{
      if($Config.Variables){
        $Config.Variables | ForEach {
          $Cipherbundle = $_
          $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
          if(-not $Unprotected -or ($ProtectionStatus.Status -eq "Unprotected")){
            [PSCustomObject]@{
              "Name" = $ConfigName
              "Type" = $ConfigSummary.Type
              "CyaPassword" = $ConfigSummary.CyaPassword
              "ProtectOnExit" = $ConfigSummary.ProtectOnExit
              "Item" = $Cipherbundle.Name
              "Status" = $ProtectionStatus.Status
            }
          }
        }
      }
      if($Config.Files){
        $Config.Files | ForEach {
          $Cipherbundle = $_
          $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
          if(-not $Unprotected -or ($ProtectionStatus.Status -eq "Unprotected")){
            [PSCustomObject]@{
              "Name" = $ConfigName
              "Type" = $ConfigSummary.Type
              "CyaPassword" = $ConfigSummary.CyaPassword
              "ProtectOnExit" = $ConfigSummary.ProtectOnExit
              "Item" = $Cipherbundle.FilePath
              "Status" = $ProtectionStatus.Status
            }
          }

          # Warn if Protected but a different file exists not in any config
          if((Test-Path $Cipherbundle.FilePath) -and ($ProtectionStatus.Status -eq "Protected")){
            $InAnotherConfig = $False
            Get-CyaConfigPath |
              Get-ChildItem |
              ForEach {
                Get-Content $_ |
                ConvertFrom-Json -Depth 3 |
                Where {$_.Type -eq "File"} |
                ForEach {
                  $PossibleMatchingConfig = $_
                  $PossibleMatchingConfig.Files |
                  Where {$_.FilePath -eq $Cipherbundle.FilePath} |
                  ForEach {
                    $PossibleMatchingCipherbundle = $_
                    if(Confirm-CipherbundleFileHash -Cipherbundle $PossibleMatchingCipherbundle){
                      $InAnotherConfig = $True
                    }
                  }
                }
              }
            if(-not $InAnotherConfig){
              $MessageFilePath = $Cipherbundle.FilePath
              $Message = "CyaConfig `"$ConfigName`" file `"$MessageFilePath`" " +
                "exists and differs from the protected file in the config. " +
                "The file may have been overwritten or modified since it was unprotected.`n"
              Write-Warning $Message
            }
          }
        }
      }
    }
  }
}

function Unprotect-CyaConfig {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    $CyaConfig,

    $Name,
    $Password
  )
  begin {
    $Configs = @()
  }
  process {
    $Config = $False
    if($Name){
      $Config = Get-CyaConfig -Name $Name
    }
    if($CyaConfig){
      $Config = $CyaConfig
    }
    if($Config){
      $Configs += $Config
    }
  }
  end{
    # nothing provided, get all configs
    if(-not $CyaConfig -and -not $Name){
      $Configs = Get-CyaConfig
    }

    # nothing to do
    if(-not $Configs){
      return
    }

    # if file exists and protected, stop we have a conflict
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json -Depth 3
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath
          if(Test-Path $FilePath){
            $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
            if($ProtectionStatus.Status -eq "Protected"){
              $Message = "Conflicting file `"$FilePath`" exists. " +
                "The file may have been overwritten or modified since it was " +
                "unprotected. Delete or rename the file to resolve the conflict."
              Write-Error $Message -ErrorAction Stop
            }
          }
        }
      }
    }

    # Get all keys
    $CyaPasswords = ($Configs.CyaPassword | Group).Name
    $Keys = @{}
    ForEach($CyaPassword in $CyaPasswords){
      if($Password){
        $Key = Get-DecryptedAnsibleVault -Path (Get-CyaPassword -Name $CyaPassword) -Password (Read-Host -AsSecureString)
        $Keys[$CyaPassword] = $Key
      }else{
        Write-Host -NoNewline "Enter password for CyaPassword `"$CyaPassword`": "
        $Key = Get-DecryptedAnsibleVault -Path (Get-CyaPassword -Name $CyaPassword) -Password (Read-Host -AsSecureString)
        $Keys[$CyaPassword] = $Key
      }
    }

    # change the environment!
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json -Depth 3
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath

          # already there
          if(Test-Path $FilePath){
            Continue
          }

          # make directory
          $Directory = Split-Path $FilePath
          mkdir -p $Directory -ErrorAction SilentlyContinue | Out-Null

          # write file
          $Cipherbundle | ConvertFrom-Cipherbundle -Key $Keys[$Config.CyaPassword] | Out-Null
        }
      }

      # set environment variables
      if($Config.Type -eq "EnvVar"){
        $Config.Variables | ConvertFrom-Cipherbundle -Key $Keys[$Config.CyaPassword] | Out-Null
      }
    }

    # Show protection status
    ForEach($Config in $Configs){
      Get-CyaConfig -Name $Config.Name -Status
    }
  }
}

function Protect-CyaConfig {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    $CyaConfig,

    $Name
  )
  begin {
    $Configs = @()
  }
  process {
    $Config = $False
    if($Name){
      $Config = Get-CyaConfig -Name $Name
    }
    if($CyaConfig){
      $Config = $CyaConfig
    }
    if($Config){
      $Configs += $Config
    }
  }
  end{
    # nothing provided, get all configs
    if(-not $CyaConfig -and -not $Name){
      $Configs = Get-CyaConfig
    }

    # nothing to do
    if(-not $Configs){
      return
    }

    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json -Depth 3

      # if file exists and unprotected, remove
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath
          if(Test-Path $FilePath){
            $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
            if($ProtectionStatus.Status -eq "Unprotected"){
              Remove-Item $FilePath
            }
          }
        }
      }

      # unset variables
      if($Config.Type -eq "EnvVar"){
        ForEach($Variable in $Config.Variables.Name){
          [System.Environment]::SetEnvironmentVariable($Variable,"")
        }
      }
    }

    # Show protection status
    ForEach($Config in $Configs){
      Get-CyaConfig -Name $Config.Name -Status
    }
  }
}

function Rename-CyaConfig {
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [Parameter(Mandatory=$true)]
    $NewName
  )
  $Config = Get-CyaConfig -Name $Name
  $OldPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Name
  $NewPath = Join-Path -Path (Get-CyaConfigPath) -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaConfig name `"$NewName`" conflicts with existing CyaConfig" -ErrorAction Stop
  }
  mv $OldPath $NewPath
}

function Remove-CyaConfig {
  param(
    [Parameter(Mandatory=$true)]
    $Name
  )
  $Config = Get-CyaConfig -Name $Name
  $Path = Join-Path -Path (Get-CyaConfigPath) -ChildPath $Name
  rm $Path
}

function Rename-CyaPassword {
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [Parameter(Mandatory=$true)]
    $NewName
  )
  $CyaPassword = Get-CyaPassword -Name $Name -ErrorAction Stop
  $OldPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name
  $NewPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaPassword name `"$NewName`" conflicts with existing CyaPassword" -ErrorAction Stop
  }

  # update all relevant CyaConfigs CyaPassword name
  ForEach($File in (Get-ChildItem (Get-CyaConfigPath))){
    $CyaConfig = $File | Get-Content | ConvertFrom-Json -Depth 3
    if($CyaConfig.CyaPassword -eq $Name){
      $CyaConfig.CyaPassword = $NewName
      $CyaConfig | ConvertTo-Json -Depth 3 | Out-File -Encoding Default $File
    }
  }

  mv $OldPath $NewPath
}

function Remove-CyaPassword {
  param(
    [Parameter(Mandatory=$true)]
    $Name
  )
  $CyaPassword = Get-CyaPassword -Name $Name -ErrorAction Stop
  # Check if any configs still use the password
  $StillInUse = @()
  if(Test-Path (Get-CyaConfigPath)){
    ForEach($File in (Get-ChildItem (Get-CyaConfigPath))){
      $CyaConfig = $File | Get-Content | ConvertFrom-Json -Depth 3
      if($CyaConfig.CyaPassword -eq $Name){
        $StillInUse += Get-CyaConfig -Name $File.Name
      }
    }
    if($StillInUse){
      $StillInUse
      $Message = "The CyaConfigs above are still using this password. " +
        "To delete the CyaPassword you must first run Remove-CyaConfig"
      Write-Error $Message -ErrorAction Stop
    }
  }

  $Path = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $Name
  rm $Path
}

$OnRemoveScript = {
  Get-CyaConfig -Unprotected | Where{($_.Type -eq "File") -and ($_.ProtectOnExit -eq $True)} | ForEach {
    $CyaConfig = $_
    if(Test-Path $CyaConfig.Item){
      rm $CyaConfig.Item
    }
  }
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $OnRemoveScript
