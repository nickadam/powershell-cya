function Get-Base64FromFile {
  [CmdletBinding()]
  [OutputType([String])]
  param([Parameter(ValueFromPipeline)]$File)
  process {
    $File = Get-Item $File -ErrorAction Stop
    $FileBytes = [System.IO.File]::ReadAllBytes($File)
    [System.Convert]::ToBase64String($FileBytes)
  }
}
