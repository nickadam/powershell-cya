function Confirm-CipherbundleFileHash {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  $Salt = $Cipherbundle.Salt
  $Hash = Get-Sha256Hash -File $Cipherbundle.FilePath -Salt $Salt
  $Hash -eq $Cipherbundle.Hash
}
