function Rename-CyaPassword {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory=$true)]
    $Name,

    [Parameter(Mandatory=$true)]
    $NewName
  )

  Get-CyaPassword -Name $Name -ErrorAction Stop | Out-Null

  $CyaPasswordPath = Get-CyaPasswordPath
  $OldPath = Join-Path -Path $CyaPasswordPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaPasswordPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Write-Error "CyaPassword name `"$NewName`" conflicts with existing CyaPassword" -ErrorAction Stop
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
