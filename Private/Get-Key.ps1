function Get-Key {
  param(
    [Parameter(Position=0, ValueFromPipeline)]
    [String]$CyaPassword = "Default",

    [Parameter(Position=1, Mandatory=$true)]
    [SecureString]$Password
  )

  $PasswordPath = Join-Path -Path (Get-CyaPasswordPath) -ChildPath $CyaPassword

  $EncryptedBin = Get-Content $PasswordPath | ConvertFrom-Json

  # Convert Ciphertext from base64
  $Bytes = [System.Convert]::FromBase64String($EncryptedBin.Ciphertext)
  $EncryptedBin.Ciphertext = $Bytes

  $Bytes = Get-DecryptedBin -EncryptedBin $EncryptedBin -Password $Password

  ConvertFrom-ByteArray -ToString -ByteArray $Bytes
}
