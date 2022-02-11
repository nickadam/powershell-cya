function Rename-CyaConfig {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)]
    $Name,

    [Parameter(Mandatory)]
    $NewName
  )

  Get-CyaConfig -Name $Name | Out-Null # will throw

  $CyaConfigPath = Get-CyaConfigPath
  $OldPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaConfigPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Throw "CyaConfig name `"$NewName`" conflicts with existing CyaConfig"
  }
  Move-Item $OldPath $NewPath
}
