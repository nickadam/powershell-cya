function Confirm-CipherbundleFileHash {
  [CmdletBinding()]
  [OutputType([Bool])]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  process {
    $Salt = $Cipherbundle.Salt
    $Hash = Get-Sha256Hash -File $Cipherbundle.FilePath -Salt $Salt
    $Hash -eq $Cipherbundle.Hash
  }
}
