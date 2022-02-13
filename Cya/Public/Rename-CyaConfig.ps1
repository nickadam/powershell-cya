function Rename-CyaConfig {
  <#
  .SYNOPSIS
  Renames a CyaConfig.

  .DESCRIPTION
  Renames a CyaConfig. If a conflicting name exists the process is aborted and
  an error message is displayed.

  .PARAMETER Name
  [String] The name of the CyaConfig

  .PARAMETER NewName
  [String] The desired new name of the CyaConfig

  .OUTPUTS
  [Null]

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Rename-CyaConfig sample sample2


  Description
  -----------
  Rename a CyaConfig.

  .LINK
  New-CyaConfig

  .LINK
  Get-CyaConfig

  .LINK
  Protect-CyaConfig

  .LINK
  Unprotect-CyaConfig

  .LINK
  Remove-CyaConfig

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

  Get-CyaConfig -Name $Name | Out-Null # will throw

  $CyaConfigPath = Get-CyaConfigPath
  $OldPath = Join-Path -Path $CyaConfigPath -ChildPath $Name
  $NewPath = Join-Path -Path $CyaConfigPath -ChildPath $NewName
  if(Test-Path $NewPath){
    Throw "CyaConfig name `"$NewName`" conflicts with existing CyaConfig"
  }
  Move-Item $OldPath $NewPath
}
