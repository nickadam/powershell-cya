function Remove-CyaConfig {
  <#
  .SYNOPSIS
  Deletes CyaConfigs.

  .DESCRIPTION
  Deletes the CyaConfig specified by name or supplied through the pipeline.

  .PARAMETER Name
  [String] The name of the CyaConfig

  .OUTPUTS
  [Null]

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Remove-CyaConfig test


  Description
  -----------
  Delete CyaConfig by name.

  .EXAMPLE
  Get-CyaConfig | Remove-CyaConfig


  Description
  -----------
  Delete all CyaConfigs.

  #>

  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    [String]$Name
  )

  process {

    Get-CyaConfig -Name $Name | Out-Null # will throw

    $CyaConfigPath = Get-CyaConfigPath
    $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name

    # delete all bin files
    $CyaConfig = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
    if($CyaConfig.Files){
      ForEach($File in $CyaConfig.Files){
        if($File.CiphertextFile){
          Remove-Item $File.CiphertextFile
        }
      }
    }

    Remove-Item $ConfigPath
  }
}
