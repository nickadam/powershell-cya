function Get-CyaPassword {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)][String]$Name
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
