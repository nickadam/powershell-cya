function ConvertFrom-Cipherbundle {
  [CmdletBinding(SupportsShouldProcess)]
  param([Parameter(ValueFromPipeline)]$Cipherbundle, $Key)
  process {
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
    $Bytes = Get-DecryptedBin -EncryptedBin $EncryptedBin -Password $Key

    if($Cipherbundle.Type -eq "EnvVar"){
      $Value = ConvertFrom-ByteArray -ToString -ByteArray $Bytes
      if($PSCmdlet.ShouldProcess($Cipherbundle.Name, 'SetEnvironmentVariable')){
        [System.Environment]::SetEnvironmentVariable($Cipherbundle.Name, $Value)
      }
    }

    if($Cipherbundle.Type -eq "File"){
      $FilePath = $Cipherbundle.FilePath
      if(Test-Path $FilePath -PathType Leaf){
        Throw "File $FilePath already exists"
      }else{
        ConvertFrom-ByteArray -ByteArray $Bytes -Destination $FilePath
      }
    }
  }
}
