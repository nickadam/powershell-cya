# Ciphertext Your Assets

# New-CyaPassword
# Get-CyaPassword
# Set-CyaPassword
# Remove-CyaPassword
# Rename-CyaPassword
#
# New-CyaConfig
# Get-CyaConfig
# Set-CyaConfig -OldPath -NewPath
# Rename-CyaConfig
# Remove-CyaConfig
# Protect-CyaConfig
# Unprotect-CyaConfig

function Get-Sha256Hash {
  param($File, $String, $Salt)

  $Sha256 = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")

  if($File){
    $File = Get-Item $File
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

function Get-RandomString {
  param($Length=64)
  $chars = "ABCDEFGHKLMNOPRSTUVWXYZabcdefghiklmnoprstuvwxyz0123456789".toCharArray()
  ($chars | Get-Random -Count $Length) -join ""
}

function Get-SecureStringText {
  param($SecureString)
  (New-Object PSCredential ".",$SecureString).GetNetworkCredential().Password
}

function Get-Key {
  param($CyaPassword, $Password)
  Get-DecryptedAnsibleVault -Path (Get-CyaPassword -Name $CyaPassword) -Password $Password
}

function Get-EncryptedAnsibleVaultString {
  param($String, $Key)
  $Password = ConvertTo-SecureString -String $Key -AsPlainText
  $TempFile = New-TemporaryFile
  Get-EncryptedAnsibleVault -Value $String -Password $Password | Out-File -Encoding Default $TempFile
  $FileBytes = [System.IO.File]::ReadAllBytes($TempFile)
  Remove-Item $TempFile
  [System.Convert]::ToBase64String($FileBytes)
}

function Get-DecryptedAnsibleVaultString {
  param($CipherTextString, $Key)
  $Password = ConvertTo-SecureString -String $Key -AsPlainText
  $TempFile = New-TemporaryFile
  $FileBytes = [System.Convert]::FromBase64String($CipherTextString)
  [System.IO.File]::WriteAllBytes($TempFile, $FileBytes)
  Get-DecryptedAnsibleVault -Path $TempFile -Password $Password
  Remove-Item $TempFile
}

$VaultPath = Join-Path -Path $Home -ChildPath ".config-vault"
$PasswordsPath = Join-Path -Path $VaultPath -ChildPath "passwords"
$ConfigsPath = Join-Path -Path $VaultPath -ChildPath "configs"

function New-CyaPassword {
  param($Name="Default", $Password)

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

  $PasswordPath = Join-Path -Path $PasswordsPath -ChildPath $Name

  if(Test-Path $PasswordPath){
    Write-Error -Message "Password $Name already exists" -ErrorAction Stop
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
      Write-Error -Message "CyaPassword `"$Name`" does not exist"
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
    $CyaPassword="Default"
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

  $ConfigPath = Join-Path -Path $ConfigsPath -ChildPath "$Name.json"

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
          Write-Host -NoNewline "$EnvVarName value: "
          $EnvVarSecureString = Read-Host -AsSecureString
          $EnvVarValue = Get-SecureStringText -SecureString $EnvVarSecureString
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

    Write-Host -NoNewline "Enter password for `"$CyaPassword`" CyaPassword: "
    $Password = Read-Host -AsSecureString
    $Key = Get-Key -CyaPassword $CyaPassword -Password $Password

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

    $CyaConfigEnvVarCollection = @()
    $EnvVarCollection | ForEach {
      $EnvVarName = $_.Name
      $EnvVarValue = $_.Value
      $EnvVarSecureString = $_.SecureString
      if($EnvVarSecureString){
        $EnvVarValue = Get-SecureStringText -SecureString $EnvVarSecureString
      }
      $CyaConfigEnvVarCollection += [PSCustomObject]@{
        "Name" = $EnvVarName
        "Ciphertext" = Get-EncryptedAnsibleVaultString -String $EnvVarValue -Key $Key
      }
    }

    if($CyaConfigEnvVarCollection.length -eq 1){
      $CyaConfig = [PSCustomObject]@{
        "Name" = $Name
        "Type" = "EnvVar"
        "Variables" = @($CyaConfigEnvVarCollection)
      }
    }else{
      $CyaConfig = [PSCustomObject]@{
        "Name" = $Name
        "Type" = "EnvVar"
        "Variables" = $CyaConfigEnvVarCollection
      }
    }

    if(-not (Test-Path $ConfigsPath)){
      mkdir -p $ConfigsPath | Out-Null
    }

    $CyaConfig | ConvertTo-Json | Out-File -Encoding Default $ConfigPath
    Get-Item $ConfigPath
  }

  if($Type -eq "File"){

  }
}
