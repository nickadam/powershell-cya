function Remove-CyaConfig {
  [CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = "FromPipeline")]
  param(
    [Parameter(Mandatory,
    ParameterSetName="FromName")]
    [String]$Name,

    [Parameter(Mandatory,
    ValueFromPipeline,
    DontShow,
    ParameterSetName="FromPipeline")]
    [Object]$InputObject
  )

  process {
    $ConfigName = $Name
    if(-not $Name -and $InputObject){
      $ConfigName = $InputObject.Name
    }

    Get-CyaConfig -Name $ConfigName | Out-Null # will throw

    $CyaConfigPath = Get-CyaConfigPath
    $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $ConfigName

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
