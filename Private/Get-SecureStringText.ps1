function Get-SecureStringText {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$SecureString)
  (New-Object PSCredential ".",$SecureString).GetNetworkCredential().Password
}
