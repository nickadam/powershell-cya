function ConvertFrom-Cipherbundle {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle, $Key)
  process {
    $Password = ConvertTo-SecureString -String $Key -AsPlainText -Force

    # get decrypted bytes from wherever
    if($Cipherbundle.CiphertextFile){
      $Bytes = [System.IO.File]::ReadAllBytes($Cipherbundle.CiphertextFile)
    }else{
      $Bytes = [System.Convert]::FromBase64String($Cipherbundle.Ciphertext)
    }
    $EncryptedBin = [PSCustomObject]@{
      "Salt" = $Cipherbundle.BinSalt
      "Hmac" = $Cipherbundle.Hmac
      "Ciphertext" = $Bytes
    }
    $Bytes = Get-DecryptedBin -EncryptedBin $EncryptedBin -Password $Password

    if($Cipherbundle.Type -eq "EnvVar"){
      $Value = ConvertFrom-ByteArray -ToString -ByteArray $Bytes
      [System.Environment]::SetEnvironmentVariable($Cipherbundle.Name, $Value)
    }

    if($Cipherbundle.Type -eq "File"){
      $FilePath = $Cipherbundle.FilePath
      if(Test-Path $FilePath -PathType Leaf){
        Write-Error "File $FilePath already exists" -ErrorAction Stop
      }else{
        ConvertFrom-ByteArray -ByteArray $Bytes -Destination $FilePath
      }
    }
  }
}
