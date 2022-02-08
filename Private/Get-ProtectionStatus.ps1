function Get-ProtectionStatus {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$Cipherbundle)
  process{
    $Status = "Protected"
    if($Cipherbundle.Type -eq "File"){
      if(Get-Item $Cipherbundle.FilePath -ErrorAction SilentlyContinue){
        if($Cipherbundle | Confirm-CipherbundleFileHash){
          $Status = "Unprotected"
        }
      }
      [PSCustomObject]@{
        "Type" = $Cipherbundle.Type
        "FilePath" = $Cipherbundle.FilePath
        "Status" = $Status
      }
    }
    if($Cipherbundle.Type -eq "EnvVar"){
      if($Cipherbundle | Confirm-CipherbundleEnvVarHash){
        $Status = "Unprotected"
      }
      [PSCustomObject]@{
        "Type" = $Cipherbundle.Type
        "Name" = $Cipherbundle.FilePath
        "Status" = $Status
      }
    }
  }
}
