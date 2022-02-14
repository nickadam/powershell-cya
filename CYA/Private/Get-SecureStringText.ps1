function Get-SecureStringText {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$SecureString)

  process {
    (New-Object PSCredential ".",$SecureString).GetNetworkCredential().Password
  }
}
