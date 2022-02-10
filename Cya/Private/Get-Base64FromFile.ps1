function Get-Base64FromFile {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$File)
  $File = Get-Item $File -ErrorAction Stop
  $FileBytes = [System.IO.File]::ReadAllBytes($File)
  [System.Convert]::ToBase64String($FileBytes)
}
