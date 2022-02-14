function Get-CyaPassword {
  <#
  .SYNOPSIS
  List encrypted CyaPasswords (decryption keys) as FileInfo

  .DESCRIPTION
  Accepts a Name and shows the corresponding FileInfo for that Name or throw an
  error. If no Name is supplied it will list all CyaPasswords.

  .PARAMETER Name
  [String] The name of the CyaPassword

  .OUTPUTS
  [Object[]] The FileInfo objects

  .NOTES
    Author: Nick Vissari

  .EXAMPLE
  Get-CyaPassword

      Directory: C:\Users\nickadam\.cya\passwords

  Mode                 LastWriteTime         Length Name
  ----                 -------------         ------ ----
  -a---           2/10/2022 10:17 AM            292 Default
  -a---           2/10/2022 10:48 AM            292 Work

  .EXAMPLE
  Get-CyaPassword Default

      Directory: C:\Users\nickadam\.cya\passwords

  Mode                 LastWriteTime         Length Name
  ----                 -------------         ------ ----
  -a---           2/10/2022 10:17 AM            292 Default

  .EXAMPLE
  "Work" | Get-CyaPassword

      Directory: C:\Users\nickadam\.cya\passwords

  Mode                 LastWriteTime         Length Name
  ----                 -------------         ------ ----
  -a---           2/10/2022 10:48 AM            292 Work

  .LINK
  New-CyaPassword

  .LINK
  Remove-CyaPassword

  .LINK
  Rename-CyaPassword

  .LINK
  https://github.com/nickadam/powershell-cya

  #>

  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [String]$Name
  )

  process {
    $CyaPasswordPath = Get-CyaPasswordPath
    if(-not (Test-Path $CyaPasswordPath)){
      return
    }
    if(-not $Name){
      Get-ChildItem $CyaPasswordPath
      return
    }
    $PasswordPath = Join-Path -Path $CyaPasswordPath -ChildPath $Name

    if(-not (Test-Path $PasswordPath -PathType Leaf)){
      Throw "CyaPassword `"$Name`" not found"
    }

    Get-Item $PasswordPath
  }
}
