function Protect-CyaConfig {
  <#
  .SYNOPSIS
  Deletes unencrypted files and unsets environment variables.

  .DESCRIPTION
  Each item in the CyaConfig is checked against the current system environment.
  If there is an environment variables set and the salted hash matches it is
  unset. If if finds a file at the same filepath and the salted hash matches,
  the file is deleted. When the salted hash differs a warning is displayed.

  .PARAMETER Name
  [String] The name of the CyaConfig

  .OUTPUTS
  [Object] CyaConfig item status

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Protect-CyaConfig

  Name          : test
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : False
  Item          : C:\Users\nickadam\test.txt
  Status        : Protected


  Description
  -----------
  With no parameters specified, all Items in all CyaConfigs are protected.

  .EXAMPLE
  Protect-CyaConfig test

  Name          : test
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : False
  Item          : C:\Users\nickadam\test.txt
  Status        : Protected


  Description
  -----------
  A specific CyaConfig can be specified by name.

  .EXAMPLE
  Get-CyaConfig test | Protect-CyaConfig

  Name          : test
  Type          : File
  CyaPassword   : Default
  ProtectOnExit : False
  Item          : C:\Users\nickadam\test.txt
  Status        : Protected


  Description
  -----------
  CyaConfigs can be supplied through the pipeline.

  #>

  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String]$Name
  )
  begin {
    $Configs = @()
  }
  process {
    if($Name){
      $Configs += Get-CyaConfig -Name $Name
    }
  }
  end{
    # nothing provided, get all configs
    if(-not $Configs){
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
            if($PSCmdlet.ShouldProcess($Variable, 'UnSetEnvironmentVariable')){
              [Environment]::SetEnvironmentVariable($Variable,"")
            }
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
