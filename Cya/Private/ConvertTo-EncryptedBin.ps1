function ConvertTo-EncryptedBin {
  [CmdletBinding(SupportsShouldProcess,
  DefaultParameterSetName = "SomethingFromPipeline")]
  param(
    [Parameter(Mandatory)]
    [String]$Key,

    [Parameter(Mandatory, ValueFromPipeline,
    ParameterSetName="FromFile")]
    [String]$FileIn,
    [Parameter(Mandatory,
    ParameterSetName="FromFile")]
    [String]$FileOut,

    [Parameter(Mandatory,
    ValueFromPipeline,
    ParameterSetName="FromString")]
    [String]$String
  )

  process {
    $Csp =  [System.Security.Cryptography.AesCryptoServiceProvider]::New()
    $Csp.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $Csp.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $Csp.BlockSize = 128
    $Csp.KeySize = 256
    $Csp.GenerateIV()
    $IV = $Csp.IV
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $KeySha = $SHA256.ComputeHash([System.Text.ASCIIEncoding]::UTF8.GetBytes($Key))
    $Encryptor = $Csp.CreateEncryptor($KeySha,$IV)

    if($PsCmdlet.ParameterSetName -eq "FromFile"){
      if($PSCmdlet.ShouldProcess($FileOut, 'WriteByte')){
        $FileInStream = [System.IO.FileStream]::New($FileIn,[System.IO.FileMode]::Open)
        $FileOutStream = [System.IO.FileStream]::new($FileOut,[System.IO.FileMode]::Create)

        $CryptoStream = [System.Security.Cryptography.CryptoStream]::New($FileOutStream, $Encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

        $FileOutStream.Write($IV,0,$IV.Count)

        do {
          try {
            $Byte = $FileInStream.ReadByte()
          } catch {
            Throw
          }
          if($Byte -ne -1){
            $CryptoStream.WriteByte($Byte)
          }
        } while ($Byte -ne -1)

        $CryptoStream.FlushFinalBlock()

        try { $FileInStream.Dispose() } catch {}
        try { $FileOutStream.Dispose() } catch {}
        try { $CryptoStream.Dispose() } catch {}
      }
    }

    if($PsCmdlet.ParameterSetName -eq "FromString"){

      $MemoryStream = [System.IO.MemoryStream]::New()
      $CryptoStream = [System.Security.Cryptography.CryptoStream]::New($MemoryStream, $Encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)

      $MemoryStream.Write($IV,0,$IV.Count)

      [System.Text.Encoding]::UTF8.GetBytes($String) | ForEach-Object {
        $CryptoStream.WriteByte($_)
      }

      $CryptoStream.FlushFinalBlock()

      # out string
      ConvertFrom-MemoryStream -MemoryStream $MemoryStream -ToBase64

      try { $CryptoStream.Dispose() } catch {}
    }
  }

}
