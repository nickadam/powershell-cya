function Remove-CyaConfig {
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
