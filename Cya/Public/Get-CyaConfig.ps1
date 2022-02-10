function Get-CyaConfig {
  [CmdletBinding()]
  param([String]$Name, [Switch]$Status, [Switch]$Unprotected)

  $CyaConfigPath = Get-CyaConfigPath
  if(-not (Test-Path $CyaConfigPath)){
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
    $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
    if(-not (Test-Path $ConfigPath -PathType Leaf)){
      Write-Error -Message "CyaConfig `"$Name`" not found" -ErrorAction Stop
    }
  }

  ForEach($Config in (Get-ChildItem $CyaConfigPath)){
    $ConfigName = $Config.Name
    if($Name -and ($ConfigName -ne $Name)){
      Continue
    }
    $Config = $Config | Get-Content | ConvertFrom-Json
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
        $Config.Variables | ForEach-Object {
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
        $Config.Files | ForEach-Object {
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
            if(-not (Get-FileExistsInCyaConfig)){
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
