function Rename-CyaConfig {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [Parameter(Mandatory=$true)]
    $NewName
  )

  Get-CyaConfig -Name $Name -ErrorAction Stop | Out-Null

  $CyaConfigPath = Get-CyaConfigPath
  $OldPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaConfigPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaConfig name `"$NewName`" conflicts with existing CyaConfig" -ErrorAction Stop
  }
  Move-Item $OldPath $NewPath
}
