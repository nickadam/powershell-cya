function Get-FileExistsInCyaConfig {
  param($Cipherbundle)
  Get-CyaConfigPath |
    Get-ChildItem |
    ForEach-Object {
      Get-Content $_ |
      ConvertFrom-Json |
      Where-Object {$_.Type -eq "File"} |
      ForEach-Object {
        $PossibleMatchingConfig = $_
        $PossibleMatchingConfig.Files |
        Where-Object {$_.FilePath -eq $Cipherbundle.FilePath} |
        ForEach-Object {
          $PossibleMatchingCipherbundle = $_
          if(Confirm-CipherbundleFileHash -Cipherbundle $PossibleMatchingCipherbundle){
            return $True
          }
        }
      }
    }
  return $False
}
