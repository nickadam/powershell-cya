function ConvertFrom-EncryptedBin {
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
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $KeySha = $SHA256.ComputeHash([System.Text.ASCIIEncoding]::UTF8.GetBytes($Key))

    if($PsCmdlet.ParameterSetName -eq "FromString"){
      $MemoryStream = ConvertTo-MemoryStream -String $String -FromBase64

      $IV = New-Object byte[] 16
      $MemoryStream.Read($IV, 0, $IV.Length) | Out-Null

      $Decryptor = $Csp.CreateDecryptor($KeySha,$IV)

      $CryptoStream = [System.Security.Cryptography.CryptoStream]::New($MemoryStream, $Decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
      $Bytes = @()
      do {
        try {
          $Byte = $CryptoStream.ReadByte()
        } catch {
          Throw "Failed to decrypt, password may be incorrect"
        }
        if($Byte -ne -1){
          $Bytes += $Byte
        }
      } while ($Byte -ne -1)

      $MemoryStream.Dispose()
      $CryptoStream.Dispose()

      [System.Text.Encoding]::UTF8.GetString($Bytes)
    }

    if($PsCmdlet.ParameterSetName -eq "FromFile"){
      if($PSCmdlet.ShouldProcess($FileOut, "WriteByte")){
        $FileInStream = [System.IO.FileStream]::New($FileIn,[System.IO.FileMode]::Open)
        $FileOutStream = [System.IO.FileStream]::new($FileOut,[System.IO.FileMode]::Create)

        $IV = New-Object byte[] 16
        $FileInStream.Read($IV, 0, $IV.Length)

        $Decryptor = $Csp.CreateDecryptor($KeySha,$IV)

        $CryptoStream = [System.Security.Cryptography.CryptoStream]::New($FileInStream, $Decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)

        $ApproxSize = (Get-Item $FileIn).Length
        Write-Progress -Activity $FileOut -Status "Decrypting" -PercentComplete 0
        $n = 0

        $Completed = $False
        try {
          do {
            try {
              $Byte = $CryptoStream.ReadByte()
            } catch {
              Throw "Decryption failed"
            }
            if($Byte -ne -1){
              $FileOutStream.WriteByte($Byte)
              $n++
            }
            if(($n % 102400) -eq 0){
              $CurrentSize = (Get-Item $FileOut).Length
              if($ApproxSize -gt 0){
                $PercentComplete = [Math]::Round(((1 - ($ApproxSize - $CurrentSize)/$ApproxSize) * 100), 1)
                Write-Progress -Activity $FileOut -Status "Decrypting $PercentComplete%" -PercentComplete $PercentComplete
              }
            }
          } while ($Byte -ne -1)

          $Completed = $True
        } finally {
          if(-not $Completed){
            Remove-Item $FileOut
            Throw "Decryption failed"
          }
        }

        $FileInStream.Dispose()
        $FileOutStream.Dispose()
        $CryptoStream.Dispose()
      }
    }
  }

}
