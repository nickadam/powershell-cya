function ConvertTo-Cipherbundle {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline)][Object]$Item,
    [Parameter(Position=1, Mandatory=$true)][String]$Key,
    [Parameter(Position=2, Mandatory=$true)][String]$Name
  )
  process {
    $Salt = Get-RandomString

    # get next filename
    $BinsPath = (Get-CyaConfigPath) -Replace "configs$", "bins"
    $n = 0
    do {
      $BinPath = Join-Path $BinsPath "$Name.$n"
      $n++
    } while(Test-Path $BinPath)

    if($Item.GetType().Name -eq "FileInfo"){
      $Hash = Get-Sha256Hash -File $Item -Salt $Salt

      if($PSCmdlet.ShouldProcess($BinPath,'WriteAllBytes')){
        # make directory
        if(-not (Test-Path $BinsPath)){
          mkdir -p $BinsPath | Out-Null
        }

        # write to file
        $Item | ConvertTo-EncryptedBin -Key $Key -FileOut $BinPath
      }

      [PSCustomObject]@{
        "Type" = "File"
        "FilePath" = $Item.FullName
        "Salt" = $Salt
        "Hash" = $Hash
        "CiphertextFile" = $BinPath
      }
    }else{ # must be environment variable
      $Hash = Get-Sha256Hash -String $Item.Value -Salt $Salt
      $Ciphertext = $Item.Value | ConvertTo-EncryptedBin -Key $Key
      [PSCustomObject]@{
        "Type" = "EnvVar"
        "Name" = $Item.Name
        "Salt" = $Salt
        "Hash" = $Hash
        "Ciphertext" = $Ciphertext
      }
    }
  }
}
