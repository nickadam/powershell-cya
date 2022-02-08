# Ciphertext Your Assets

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
