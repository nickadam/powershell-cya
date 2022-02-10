function Get-CyaConfig {
  <#
  .SYNOPSIS
  List information about CyaConfigs

  .DESCRIPTION
  Accepts a Name and shows the corresponding CyaConfig for that Name or throw an
  error. If no Name is supplied it will list all CyaConfigs.DESCRIPTION

  If the Status switch is supplied, the protection status of each item in the
  CyaConfig(s) will be returned.

  If the Unprotected switch is supplied, only the unprotected items in the
  CyaConfig(s) will be returned.

  .PARAMETER Name
  [String] The name of the CyaConfig

  .PARAMETER Status
  [SwitchParameter] If you want to return the status of each item in the config(s)

  .PARAMETER Unprotected
  [SwitchParameter] If you want to return information about all unprotected
  items in the config(s)

  .OUTPUTS
  [Object[]] The CyaConfig summary objects or the CyaConfig Item status objects

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Get-CyaConfig | ft

  Name    Type   CyaPassword ProtectOnExit Variables        Files
  ----    ----   ----------- ------------- ---------        -----
  sample1 EnvVar Default              True {MYVAR1, MYVAR2}
  sample2 File   Default             False                  {C:\Users\nickadam\test.txt, C:\Users\nickadam\test2.txt}


  Description
  -----------
  All CyaConfigs displayed in summary format.

  .EXAMPLE
  Get-CyaConfig -Name sample1 -Status

  Name          : sample1
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYVAR1
  Status        : Protected

  Name          : sample1
  Type          : EnvVar
  CyaPassword   : Default
  ProtectOnExit : True
  Item          : MYVAR2
  Status        : Protected


  Description
  -----------
  The protection status of all items associated with CyaConfig sample1.

  .EXAMPLE
  Get-CyaConfig -Unprotected | ft

  Name    Type   CyaPassword ProtectOnExit Item                        Status
  ----    ----   ----------- ------------- ----                        ------
  sample1 EnvVar Default              True MYVAR1                      Unprotected
  sample1 EnvVar Default              True MYVAR2                      Unprotected
  sample2 File   Default             False C:\Users\nickadam\test.txt  Unprotected
  sample2 File   Default             False C:\Users\nickadam\test2.txt Unprotected


  Description
  -----------
  All unprotected items in the current shell (for environment variables)
  and filesystem (for files).

  #>

  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [String]$Name,
    [Switch]$Status,
    [Switch]$Unprotected
  )

  process {
    $CyaConfigPath = Get-CyaConfigPath
    if(-not (Test-Path $CyaConfigPath)){
      return
    }

    # error if not found
    if($Name){
      $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
      if(-not (Test-Path $ConfigPath -PathType Leaf)){
        Throw "CyaConfig `"$Name`" not found"
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
}
