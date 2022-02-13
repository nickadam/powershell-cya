function Get-Sha256Hash {
  param($File, $String, $Salt)

  $Sha256 = [System.Security.Cryptography.HashAlgorithm]::Create("sha256")

  if($File){
    $hash = (Get-FileHash $File).Hash.toLower()
    if($Salt){
      $String = $Salt + $hash
      $hashBytes = $Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))
      $hash = [System.BitConverter]::ToString($hashBytes)
      $hash = $hash.toLower() -replace "-", ""
    }
    $hash
  }elseif($String){
    if($Salt){
      $String = $Salt + $String
    }
    $hashBytes = $Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))
    $hash = [System.BitConverter]::ToString($hashBytes)
    $hash.toLower() -replace "-", ""
  }
}
