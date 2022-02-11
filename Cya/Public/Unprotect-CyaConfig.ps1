function Unprotect-CyaConfig {
  [CmdletBinding()]
  param(
    [String]$Name,

    [Parameter(ValueFromPipeline)]
    [Object]$CyaConfig,

    [SecureString]$Password
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
      Write-Warning "No CyaConfigs specified or found."
      return
    }

    $CyaConfigPath = Get-CyaConfigPath

    # if file exists and protected, stop we have a conflict
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
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
    $CyaPasswords = ($Configs.CyaPassword | Group-Object).Name
    $Keys = @{}
    ForEach($CyaPassword in $CyaPasswords){
      if(-not $Password){
        $Password = Read-Host -Prompt "Enter password for CyaPassword `"$CyaPassword`"" -AsSecureString
      }
      $Key = Get-Key -CyaPassword $CyaPassword -Password $Password -ErrorAction Stop
      $Keys[$CyaPassword] = $Key
    }

    # change the environment!
    ForEach($Config in $Configs){
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
      if($Config.Type -eq "File"){
        ForEach($Cipherbundle in $Config.Files){
          $FilePath = $Cipherbundle.FilePath

          # already there
          if(Test-Path $FilePath){
            Continue
          }

          # make directory
          $Directory = Split-Path $FilePath
          if(-not (Test-Path $Directory)){
            mkdir -p $Directory | Out-Null
          }

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
