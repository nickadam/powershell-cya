function ConvertTo-Cipherbundle {
  [CmdletBinding()]
  param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)][Object]$Item,
    [Parameter(Position=1, Mandatory=$true)][String]$Key,
    [Parameter(Position=2, Mandatory=$true)][String]$Name
  )
  process {
    $Salt = Get-RandomString
    $Password = ConvertTo-SecureString -String $Key -AsPlainText -Force

    # get next filename
    $BinsPath = (Get-CyaConfigPath) -Replace "configs$", "bins"
    $n = 0
    do {
      $BinPath = Join-Path $BinsPath "$Name.$n"
      $n++
    } while(Test-Path $BinPath)

    if($Item.GetType().Name -eq "FileInfo"){
      $Hash = Get-Sha256Hash -File $Item -Salt $Salt
      $EncryptedBin = ConvertTo-ByteArray -File $Item | Get-EncryptedBin -Password $Password
      if($EncryptedBin.Ciphertext.length -gt 1024){

        # make directory
        if(-not (Test-Path $BinsPath)){
          mkdir -p $BinsPath | Out-Null
        }

        # write to file
        [System.IO.File]::WriteAllBytes($BinPath, $EncryptedBin.Ciphertext)

        [PSCustomObject]@{
          "Type" = "File"
          "FilePath" = $Item.FullName
          "Salt" = $Salt
          "Hash" = $Hash
          "BinSalt" = $EncryptedBin.Salt
          "Hmac" = $EncryptedBin.Hmac
          "CiphertextFile" = $BinPath
        }
      }else{
        [PSCustomObject]@{
          "Type" = "File"
          "FilePath" = $Item.FullName
          "Salt" = $Salt
          "Hash" = $Hash
          "BinSalt" = $EncryptedBin.Salt
          "Hmac" = $EncryptedBin.Hmac
          "Ciphertext" = [System.Convert]::ToBase64String($EncryptedBin.Ciphertext)
        }
      }
    }

    if($Item.GetType().Name -eq "PSCustomObject"){
      $Hash = Get-Sha256Hash -String $Item.Value -Salt $Salt
      $EncryptedBin = ConvertTo-ByteArray -String $Item.Value | Get-EncryptedBin -Password $Password
      if($EncryptedBin.Ciphertext.length -gt 1024){
        # make directory
        if(-not (Test-Path $BinsPath)){
          mkdir -p $BinsPath | Out-Null
        }

        # write to file
        [System.IO.File]::WriteAllBytes($BinPath, $EncryptedBin.Ciphertext)

        [PSCustomObject]@{
          "Type" = "EnvVar"
          "Name" = $Item.Name
          "Salt" = $Salt
          "Hash" = $Hash
          "BinSalt" = $EncryptedBin.Salt
          "Hmac" = $EncryptedBin.Hmac
          "CiphertextFile" = $BinPath
        }
      }else{
        [PSCustomObject]@{
          "Type" = "EnvVar"
          "Name" = $Item.Name
          "Salt" = $Salt
          "Hash" = $Hash
          "BinSalt" = $EncryptedBin.Salt
          "Hmac" = $EncryptedBin.Hmac
          "Ciphertext" = [System.Convert]::ToBase64String($EncryptedBin.Ciphertext)
        }
      }
    }
  }
}
