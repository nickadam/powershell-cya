function Confirm-CipherbundleEnvVarHash {
  [CmdletBinding()]
  [OutputType([Bool])]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  process {
    $Name = $Cipherbundle.Name
    $Salt = $Cipherbundle.Salt
    $String = Get-EnvVarValueByName -Name $Name
    if(-not $String){
      $False
    }else{
      $Hash = Get-Sha256Hash -String $String -Salt $Salt
      $Hash -eq $Cipherbundle.Hash
    }
  }
}
