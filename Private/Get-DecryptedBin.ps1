# Copyright: (c) 2018, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see LICENSE or https://opensource.org/licenses/MIT)

Function Get-DecryptedBin {
    [OutputType([Array])]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline, ValueFromPipelineByPropertyName)] [Object]$EncryptedBin,
        [Parameter(Position=1, Mandatory=$true)] [SecureString]$Password
    )

    $salt = Convert-HexToByte -Value $EncryptedBin.Salt
    $expected_hmac = $EncryptedBin.Hmac
    $encrypted_bytes = $EncryptedBin.Ciphertext

    $cipher_key, $hmac_key, $nonce = New-VaultKey -Password $password -Salt $salt

    $actual_hmac = Get-HMACValue -Value $encrypted_bytes -Key $hmac_key
    if ($actual_hmac -ne $expected_hmac) {
        throw [System.ArgumentException]"HMAC verification failed, was the wrong password entered?"
    }

    $decrypted_bytes = Invoke-AESCTRCycle -Value $encrypted_bytes -Key $cipher_key -Nonce $nonce

    # Need to manually remove the padding as AES CTR has no concept of padding
    # it is a stream mode
    $unpadded_bytes = Remove-Pkcs7Padding -Value $decrypted_bytes -BlockSize 128

    return $unpadded_bytes
}
