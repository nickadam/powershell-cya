function Rename-CyaPassword {
  <#
  .SYNOPSIS
  Renames a CyaPassword.

  .DESCRIPTION
  Renames a CyaPassword. If a conflicting name exists the process is aborted and
  an error message is displayed. Any CyaConfigs using the old CyaPassword name
  will be updated to use the new name.

  .PARAMETER Name
  [String] The name of the CyaPassword

  .PARAMETER NewName
  [String] The desired new name of the CyaPassword

  .OUTPUTS
  [Null]

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Rename-CyaPassword Default OldDefault


  Description
  -----------
  Rename a CyaPassword.

  .LINK
  Get-CyaPassword

  .LINK
  New-CyaPassword

  .LINK
  Remove-CyaPassword

  .LINK
  https://github.com/nickadam/powershell-cya

  #>

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
      $CyaConfig | ConvertTo-Json | Out-File -Encoding Default $File.FullName
    }
  }

  Move-Item $OldPath $NewPath
}
