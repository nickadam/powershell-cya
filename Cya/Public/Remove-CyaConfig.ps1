function Remove-CyaConfig {
  param(
    [Parameter(Mandatory=$true)]
    $Name
  )

  Get-CyaConfig -Name $Name -ErrorAction Stop | Out-Null

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
