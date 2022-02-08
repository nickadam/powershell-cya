# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-EncryptedBin {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)] [Array]$Bytes,
        [Parameter(Position=1, Mandatory=$true)] [String]$Password
    )
    begin {
      $AllBytes = @()
    }
    process {
      $AllBytes += $Bytes
    }

    end {
      $bytes_to_encrypt = $AllBytes

      # Generate a secure random salt value
      $salt = New-Object -TypeName byte[] -ArgumentList 32
      $random_gen = New-Object -TypeName System.Security.Cryptography.RNGCryptoServiceProvider
      $random_gen.GetBytes($salt)

      $cipher_key, $hmac_key, $nonce = New-VaultKey -Password $Password -Salt $salt

      # While AES CTR is a stream mode, Ansible still pads the bytes we we need
      # to do that here
      $padded_bytes = Add-Pkcs7Padding -Value $bytes_to_encrypt -BlockSize 128
      $encrypted_bytes = Invoke-AESCTRCycle -Value $padded_bytes -Key $cipher_key -Nonce $nonce
      $actual_hmac = Get-HMACValue -Value $encrypted_bytes -Key $hmac_key

      return [PSCustomObject]@{
        "Salt" = (Convert-ByteToHex -Value $salt)
        "Hmac" = $actual_hmac
        "Ciphertext" = $encrypted_bytes
      }
    }
}
