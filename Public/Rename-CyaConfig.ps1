function Rename-CyaConfig {
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [Parameter(Mandatory=$true)]
    $NewName
  )
  $Config = Get-CyaConfig -Name $Name
  $CyaConfigPath = Get-CyaConfigPath
  $OldPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaConfigPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaConfig name `"$NewName`" conflicts with existing CyaConfig" -ErrorAction Stop
  }
  Move-Item $OldPath $NewPath
}
