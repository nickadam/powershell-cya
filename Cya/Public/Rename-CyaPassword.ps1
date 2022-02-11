function Rename-CyaPassword {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    $Name,

    [Parameter(Mandatory)]
    $NewName
  )

  Get-CyaPassword -Name $Name | Out-Null # will throw

  $CyaPasswordPath = Get-CyaPasswordPath
  $OldPath = Join-Path -Path $CyaPasswordPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaPasswordPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Throw "CyaPassword name `"$NewName`" conflicts with existing CyaPassword"
  }

  # update all relevant CyaConfigs CyaPassword name
  $CyaConfigPath = Get-CyaConfigPath
  ForEach($File in (Get-ChildItem $CyaConfigPath)){
    $CyaConfig = $File | Get-Content | ConvertFrom-Json
    if($CyaConfig.CyaPassword -eq $Name){
      $CyaConfig.CyaPassword = $NewName
      $CyaConfig | ConvertTo-Json | Out-File -Encoding Default $File
    }
  }

  Move-Item $OldPath $NewPath
}
