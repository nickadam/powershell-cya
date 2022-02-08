function Get-Sha256Hash {
  param($File, $String, $Salt)

  $Sha256 = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")

  if($File){
    $File = Get-Item $File -ErrorAction Stop
    if($Salt){
      $FileBytes = [System.IO.File]::ReadAllBytes($File)
      $SaltBytes = [System.Text.Encoding]::UTF8.getBytes($Salt)
      $hashBytes = $Sha256.ComputeHash($SaltBytes + $FileBytes)
      $hash = [System.BitConverter]::ToString($hashBytes)
      $hash.toLower() -replace "-", ""
    }else{
      # just file path, use get-filehash
      (Get-FileHash $File).Hash.toLower()
    }
  }elseif($String){
    if($Salt){
      $String = $Salt + $String
    }
    $hashBytes = $Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))
    $hash = [System.BitConverter]::ToString($hashBytes)
    $hash.toLower() -replace "-", ""
  }
}
