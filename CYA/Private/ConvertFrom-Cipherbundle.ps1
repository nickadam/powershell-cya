function ConvertFrom-Cipherbundle {
  [CmdletBinding(SupportsShouldProcess)]
  param([Parameter(ValueFromPipeline)]$Cipherbundle, $Key)
  process {
    if($Cipherbundle.Type -eq "EnvVar"){
      $Value = ConvertFrom-EncryptedBin -String $Cipherbundle.Ciphertext -Key $Key
      if($PSCmdlet.ShouldProcess($Cipherbundle.Name, 'SetEnvironmentVariable')){
        [System.Environment]::SetEnvironmentVariable($Cipherbundle.Name, $Value)
      }
    }

    if($Cipherbundle.Type -eq "File"){
      $FilePath = $Cipherbundle.FilePath
      if(Test-Path $FilePath -PathType Leaf){
        Throw "File $FilePath already exists"
      }else{
        ConvertFrom-EncryptedBin -FileIn $Cipherbundle.CiphertextFile -FileOut $Cipherbundle.FilePath -Key $Key
      }
    }
  }
}
