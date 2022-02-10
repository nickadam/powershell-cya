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

    $EncryptedBin = Get-Content $PasswordPath | ConvertFrom-Json

    # Convert Ciphertext from base64
    $Bytes = [System.Convert]::FromBase64String($EncryptedBin.Ciphertext)
    $EncryptedBin.Ciphertext = $Bytes

    $Key = Get-SecureStringText $SSKey
    $Bytes = Get-DecryptedBin -EncryptedBin $EncryptedBin -Password $Key

    ConvertFrom-ByteArray -ToString -ByteArray $Bytes
  }
}
