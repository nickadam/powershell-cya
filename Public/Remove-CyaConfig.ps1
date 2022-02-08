function Remove-CyaConfig {
  param(
    [Parameter(Mandatory=$true)]
    $Name
  )
  $Config = Get-CyaConfig -Name $Name -ErrorAction Stop

  $CyaConfigPath = Get-CyaConfigPath
  $ConfigPath = Join-Path -Path $CyaConfigPath -ChildPath $Name

  # delete all bin files
  $CyaConfig = Get-Item $ConfigPath | Get-Content | ConvertFrom-Json
  if($CyaConfig.Files){
    ForEach($File in $CyaConfig.Files){
      if($File.CiphertextFile){
        rm $File.CiphertextFile
      }
    }
  }

  rm $ConfigPath
}
