function Get-Key {
  [CmdletBinding()]
  param(
    [Parameter(Position=0, ValueFromPipeline)]
    [alias("CyaPassword")]
    [String]$CyaPwName = "Default",

    [Parameter(Position=1, Mandatory=$true)]
    [alias("Password")]
    [SecureString]$SSKey
  )

  process {
    $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $CyaPwName

    $Ciphertext = Get-Content $PasswordPath

    $Key = Get-SecureStringText $SSKey
    $Ciphertext | ConvertFrom-EncryptedBin -Key $Key
  }
}
