# Ciphertext Your Assets

# Set-CyaPassword ??? reset lots of work
# Remove-CyaPassword
# Rename-CyaPassword
#
# Set-CyaConfig -OldPath -NewPath
# Remove-CyaConfig
# Protect-CyaConfig (on exit)

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
    Get-EncryptedAnsibleVault -Value $String -Password $Password #  | Out-File -Encoding Default $TempFile
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

$VaultPath = Join-Path -Path $Home -ChildPath ".cya"
$PasswordsPath = Join-Path -Path $VaultPath -ChildPath "passwords"
$ConfigsPath = Join-Path -Path $VaultPath -ChildPath "configs"

function New-CyaPassword {
  param($Name="Default", $Password)

  $PasswordPath = Join-Path -Path $PasswordsPath -ChildPath $Name

  if(Test-Path $PasswordPath){
    Write-Error -Message "Password $Name already exists" -ErrorAction Stop
  }

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

  if(-not (Test-Path $PasswordsPath)){
    mkdir -p $PasswordsPath | Out-Null
  }

  Get-EncryptedAnsibleVault -Value (Get-RandomString) -Password $Password | Out-File -Encoding Default $PasswordPath
}

function Get-CyaPassword {
  [CmdletBinding()]
  param($Name)
  if(-not (Test-Path $PasswordsPath)){
    return
  }
  if($Name){
    $PasswordPath = Join-Path -Path $PasswordsPath -ChildPath $Name
    if(Test-Path $PasswordPath -PathType Leaf){
      Get-Item $PasswordPath
    }else{
      Write-Error -Message "CyaPassword `"$Name`" not found"
    }
  }else{
    Get-ChildItem $PasswordsPath
  }
}

function New-CyaConfig {
  param(
    $Name,

    [ValidateSet("EnvVar", "File")]
    $Type,

    $EnvVarName,
    $EnvVarValue,
    $EnvVarSecureString,
    $EnvVarCollection,
    $File,

    [ValidateSet($True, $False)]
    $ProtectOnExit,

    $CyaPassword="Default",
    $Password
  )

  if(-not (Get-CyaPassword -Name $CyaPassword -EA SilentlyContinue)){
    Write-Warning "CyaPassword `"$CyaPassword`" password not found, creating now with New-CyaPassword."
    New-CyaPassword -Name $CyaPassword
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

  # get the name
  if(-not $Name){
    Write-Host -NoNewline "Config name: "
    $Name = Read-Host
  }
  if(-not $Name){
    Write-Error -Message "Config name is required" -ErrorAction Stop
  }

  $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath $Name

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

    if(-not (Test-Path $ConfigsPath)){
      mkdir -p $ConfigsPath | Out-Null
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

function Get-CyaConfig {
  [CmdletBinding()]
  param($Name, [Switch]$Status, [Switch]$Unprotected)
  if(-not (Test-Path $ConfigsPath)){
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
    $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath $Name
    if(-not (Test-Path $ConfigPath -PathType Leaf)){
      Write-Error -Message "CyaConfig `"$Name`" not found" -ErrorAction Stop
    }
  }

  ForEach($Config in Get-ChildItem $ConfigsPath){
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
      $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json -Depth 3
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath
          if(Test-Path $FilePath){
            $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
            if($ProtectionStatus.Status -eq "Protected"){
              $Message = "Conflicting file `"$FilePath`" exists. " +
                "The file may have been modified since it was last protected. " +
                "Delete or rename the file to resolve the conflict."
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
      $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath $Config.Name
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
      $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath $Config.Name
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
  $OldPath = Join-Path -Path $ConfigsPath -ChildPath $Name
  $NewPath = Join-Path -Path $ConfigsPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaConfig name `"$NewName`" conflicts with existing CyaConfig"
  }
  mv $OldPath $NewPath
}
