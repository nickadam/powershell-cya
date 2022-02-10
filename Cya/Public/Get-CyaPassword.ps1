function Get-CyaPassword {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)][String]$Name
  )
  $CyaPasswordPath = Get-CyaPasswordPath
  if(-not (Test-Path $CyaPasswordPath)){
    return
  }
  if($Name){
    $PasswordPath = Join-Path -Path $CyaPasswordPath -ChildPath $Name
    if(Test-Path $PasswordPath -PathType Leaf){
      Get-Item $PasswordPath
    }else{
      Write-Error -Message "CyaPassword `"$Name`" not found"
    }
  }else{
    Get-ChildItem $CyaPasswordPath
  }
}
