function Protect-CyaConfig {
  [CmdletBinding()]
  param(
    $Name,

    [Parameter(ValueFromPipeline)]
    $CyaConfig
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

    ForEach($Config in $Configs){
      $CyaConfigPath = Get-CyaConfigPath
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Config.Name
      $Config = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json

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
        ForEach($Cipherbundle in $Config.Variables){
          $Variable = $Cipherbundle.Name
          # if the hashes match, remove
          $ProtectionStatus = $Cipherbundle | Get-ProtectionStatus
          if($ProtectionStatus.Status -eq "Unprotected"){
            [System.Environment]::SetEnvironmentVariable($Variable,"")
          }
        }
      }
    }

    # Show protection status
    ForEach($Config in $Configs){
      Get-CyaConfig -Name $Config.Name -Status
    }
  }
}
